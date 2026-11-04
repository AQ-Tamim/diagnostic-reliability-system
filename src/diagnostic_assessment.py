
from db import get_connection
from .bayesian_diagnostic import BayesianDiagnosticModel


def fetch_diagnostic_data(cursor):
    query = """
        SELECT
            tr.result_id,
            tr.interpretation,
            tp.performance_id,
            tp.sensitivity,
            tp.specificity,
            dp.prevalence_id,
            dp.prevalence,
            mv.model_version_id

        FROM TEST_RESULT tr

        JOIN TEST_ORDER o
            ON tr.order_id = o.order_id

        JOIN TEST_PERFORMANCE tp
            ON o.test_id = tp.test_id
            AND tp.effective_from <= DATE(tr.performed_at)
            AND (
                tp.effective_to IS NULL
                OR tp.effective_to >= DATE(tr.performed_at)
            )

        JOIN DISEASE_PREVALENCE dp
            ON tp.disease_id = dp.disease_id
            AND dp.effective_from <= DATE(tr.performed_at)
            AND (
                dp.effective_to IS NULL
                OR dp.effective_to >= DATE(tr.performed_at)
            )

        JOIN MODEL_VERSION mv
            ON mv.model_name = 'Bayesian Diagnostic Assessment'
            AND mv.version_number = '1.0'

        WHERE o.order_status = 'Completed'

        ORDER BY tr.result_id;
    """

    cursor.execute(query)
    return cursor.fetchall()


def update_assessment(cursor, assessment):
    query = """
        INSERT INTO BAYESIAN_ASSESSMENT (
            result_id,
            performance_id,
            prevalence_id,
            model_version_id,
            posterior_probability
        )

        VALUES (%s, %s, %s, %s, %s)

        ON DUPLICATE KEY UPDATE
            posterior_probability = VALUES(posterior_probability),
            assessed_at = CURRENT_TIMESTAMP;
    """

    cursor.execute(
        query,
        (
            assessment["result_id"],
            assessment["performance_id"],
            assessment["prevalence_id"],
            assessment["model_version_id"],
            assessment["posterior_probability"],
        ),
    )


def run_assessment():
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        diagnostic_data = fetch_diagnostic_data(cursor)

        if not diagnostic_data:
            print("No completed diagnostic results found.")
            return

        processed_count = 0

        for row in diagnostic_data:

            model = BayesianDiagnosticModel(
                prevalence=float(row["prevalence"]),
                sensitivity=float(row["sensitivity"]),
                specificity=float(row["specificity"]),
            )

            result = model.calculate(row["interpretation"])

            assessment = {
                "result_id": row["result_id"],
                "performance_id": row["performance_id"],
                "prevalence_id": row["prevalence_id"],
                "model_version_id": row["model_version_id"],
                "posterior_probability": result[
                    "posterior_probability"
                ],
            }

            update_assessment(cursor, assessment)

            processed_count += 1

        connection.commit()

        print("Bayesian diagnostic integration completed.")
        print(f"Assessments processed: {processed_count}")

    except Exception as error:
        connection.rollback()

        print("Assessment failed.")
        print(f"Error: {error}")

        raise

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


if __name__ == "__main__":
    run_assessment()
