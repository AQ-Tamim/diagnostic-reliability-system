
from scipy.stats import beta

from db import get_connection


FAILURE_LIMIT = 0.10
POSTERIOR_CONFIDENCE = 0.90


def fetch_integrated_assessments(cursor):

    query = """
        SELECT
            tr.result_id,
            tr.equipment_id,
            tr.performed_at,
            tr.interpretation,
            ba.posterior_probability,

            era.reliability_assessment_id,
            era.observation_start,
            era.observation_end,
            era.qc_observations,
            era.qc_failures,
            era.posterior_alpha,
            era.posterior_beta,
            era.posterior_mean_failure_probability,
            era.failure_probability_ci_lower,
            era.failure_probability_ci_upper

        FROM TEST_RESULT tr

        JOIN BAYESIAN_ASSESSMENT ba
            ON tr.result_id = ba.result_id

        LEFT JOIN EQUIPMENT_RELIABILITY_ASSESSMENT era
            ON era.reliability_assessment_id = (
                SELECT era2.reliability_assessment_id

                FROM EQUIPMENT_RELIABILITY_ASSESSMENT era2

                WHERE era2.equipment_id = tr.equipment_id
                  AND DATE(tr.performed_at)
                      BETWEEN era2.observation_start
                      AND era2.observation_end

                ORDER BY
                    era2.observation_end DESC,
                    era2.reliability_assessment_id DESC

                LIMIT 1
            )

        ORDER BY tr.result_id;
    """

    cursor.execute(query)

    return cursor.fetchall()



def calculate_posterior_probability(row):

    posterior_alpha = row["posterior_alpha"]
    posterior_beta = row["posterior_beta"]

    if posterior_alpha is None or posterior_beta is None:
        return None

    posterior_alpha = float(posterior_alpha)
    posterior_beta = float(posterior_beta)

    probability = 1 - beta.cdf(
        FAILURE_LIMIT,
        posterior_alpha,
        posterior_beta
    )

    return probability

def classify_assessment(row):

    posterior_probability = calculate_posterior_probability(row)

    if posterior_probability is None:
        return "RELIABILITY_DATA_UNAVAILABLE"

    if posterior_probability >= POSTERIOR_CONFIDENCE:
        return "REVIEW_RECOMMENDED"

    return "REVIEW_NOT_TRIGGERED"


def run_integration():

    connection = get_connection()
    cursor = None

    try:

        cursor = connection.cursor(dictionary=True)

        records = fetch_integrated_assessments(cursor)

        if not records:
            print("No diagnostic assessments found.")
            return

        print("\nRELIABILITY-AWARE DIAGNOSTIC ASSESSMENT")
        print("=" * 100)

        print(
            f"Review rule: P(failure rate > {FAILURE_LIMIT:.0%} | QC data)"
            f" >= {POSTERIOR_CONFIDENCE:.0%}"
        )

        print("-" * 100)

        for row in records:

            classification = classify_assessment(row)

            posterior_probability = calculate_posterior_probability(
                row
            )

            if posterior_probability is None:
                review_probability = "Unavailable"
            else:
                review_probability = f"{posterior_probability:.4f}"

            failure_probability = (
                row["posterior_mean_failure_probability"]
            )

            if failure_probability is None:
                failure_display = "Unavailable"
            else:
                failure_display = f"{failure_probability:.4f}"

            print(
                f"Result ID: {row['result_id']} | "
                f"Equipment: {row['equipment_id']} | "
                f"Diagnostic posterior: "
                f"{row['posterior_probability']:.7f} | "
                f"Mean failure probability: {failure_display} | "
                f"P(failure > {FAILURE_LIMIT:.0%}): "
                f"{review_probability} | "
                f"Classification: {classification}"
            )

        print("-" * 100)
        print(f"Total diagnostic results: {len(records)}")

    except Exception as error:

        print("Integration failed.")
        print(f"Error: {error}")

        raise

    finally:

        if cursor is not None:
            cursor.close()

        connection.close()


if __name__ == "__main__":
    run_integration()
