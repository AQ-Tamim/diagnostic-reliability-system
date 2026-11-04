
from collections import defaultdict

from db import get_connection
from .beta_binomial import BetaBinomialModel
from .reliability_storage import save_reliability_assessments


def fetch_quality_control_observations():
    """
    Retrieve historical QC observations from MariaDB.
    """

    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        query = """
            SELECT
                qc_id,
                equipment_id,
                observation_date,
                expected_value,
                observed_value,
                qc_status
            FROM QUALITY_CONTROL
            ORDER BY equipment_id, observation_date;
        """

        cursor.execute(query)

        return cursor.fetchall()

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


def summarize_equipment_observations(observations):
    """
    Group QC observations by equipment.
    """

    equipment_summary = defaultdict(
        lambda: {
            "total": 0,
            "passed": 0,
            "failed": 0
        }
    )

    for observation in observations:

        equipment_id = observation["equipment_id"]
        status = observation["qc_status"]

        equipment_summary[equipment_id]["total"] += 1

        if status == "Passed":
            equipment_summary[equipment_id]["passed"] += 1

        elif status == "Failed":
            equipment_summary[equipment_id]["failed"] += 1

        else:
            raise ValueError(
                f"Unexpected QC status: {status}"
            )

    return dict(equipment_summary)


if __name__ == "__main__":

    # 1. Retrieve QC observations.
    observations = fetch_quality_control_observations()

    # 2. Summarize observations.
    summary = summarize_equipment_observations(observations)

    # 3. Initialize the Bayesian model.
    model = BetaBinomialModel(
        alpha=1.0,
        beta_param=1.0
    )

    # 4. Store model results in a dictionary.
    model_results = {}

    print("\nEQUIPMENT RELIABILITY ESTIMATES")
    print("=" * 75)

    for equipment_id, values in summary.items():

        result = model.fit(
            failures=values["failed"],
            total_observations=values["total"]
        )

        model_results[equipment_id] = result

        print(f"\nEquipment ID: {equipment_id}")
        print(f"QC observations: {values['total']}")
        print(f"QC failures: {values['failed']}")

        print(
            f"Posterior distribution: "
            f"Beta({result['posterior_alpha']:.2f}, "
            f"{result['posterior_beta']:.2f})"
        )

        print(
            f"Mean failure probability: "
            f"{result['mean_failure_probability']:.2%}"
        )

        print(
            f"Mean reliability: "
            f"{result['mean_reliability']:.2%}"
        )

        print(
            f"95% credible interval: "
            f"[{result['failure_probability_ci_lower']:.2%}, "
            f"{result['failure_probability_ci_upper']:.2%}]"
        )

    # 5. Persist the calculated results.
    save_reliability_assessments(
        observations,
        summary,
        model_results
    )
