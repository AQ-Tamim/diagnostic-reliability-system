
from db import get_connection


def save_reliability_assessments(
    observations,
    summary,
    model_results,
    model_name="Beta-Binomial Equipment Reliability",
    version_number="1.0"
):
    """
    Save Python-generated equipment reliability assessments
    into MariaDB.
    """

    if not observations:
        print("No QC observations available. Nothing to save.")
        return

    # Determine the observation period for each equipment unit.
    observation_dates = {}

    for observation in observations:
        equipment_id = observation["equipment_id"]
        observation_date = observation["observation_date"]

        if equipment_id not in observation_dates:
            observation_dates[equipment_id] = []

        observation_dates[equipment_id].append(observation_date)

    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        # Retrieve the registered model version.
        cursor.execute(
            """
            SELECT model_version_id
            FROM MODEL_VERSION
            WHERE model_name = %s
              AND version_number = %s
            """,
            (model_name, version_number)
        )

        model_record = cursor.fetchone()

        if model_record is None:
            raise ValueError(
                f"Model version not found: {model_name} {version_number}"
            )

        model_version_id = model_record["model_version_id"]

        insert_query = """
            INSERT INTO EQUIPMENT_RELIABILITY_ASSESSMENT (
                equipment_id,
                model_version_id,
                observation_start,
                observation_end,
                prior_alpha,
                prior_beta,
                qc_observations,
                qc_failures,
                posterior_alpha,
                posterior_beta,
                posterior_mean_failure_probability,
                failure_probability_ci_lower,
                failure_probability_ci_upper
            )
            VALUES (
                %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s
            )
            ON DUPLICATE KEY UPDATE
                prior_alpha = VALUES(prior_alpha),
                prior_beta = VALUES(prior_beta),
                qc_observations = VALUES(qc_observations),
                qc_failures = VALUES(qc_failures),
                posterior_alpha = VALUES(posterior_alpha),
                posterior_beta = VALUES(posterior_beta),
                posterior_mean_failure_probability =
                    VALUES(posterior_mean_failure_probability),
                failure_probability_ci_lower =
                    VALUES(failure_probability_ci_lower),
                failure_probability_ci_upper =
                    VALUES(failure_probability_ci_upper),
                assessed_at = CURRENT_TIMESTAMP
        """

        saved_count = 0

        for equipment_id, values in summary.items():

            result = model_results[equipment_id]

            dates = observation_dates[equipment_id]

            observation_start = min(dates)
            observation_end = max(dates)

            parameters = (
                equipment_id,
                model_version_id,
                observation_start,
                observation_end,
                result["prior_alpha"],
                result["prior_beta"],
                values["total"],
                values["failed"],
                result["posterior_alpha"],
                result["posterior_beta"],
                result["mean_failure_probability"],
                result["failure_probability_ci_lower"],
                result["failure_probability_ci_upper"]
            )

            cursor.execute(insert_query, parameters)
            saved_count += 1

        connection.commit()

        print("\nDATABASE PERSISTENCE")
        print("-" * 50)

        print("Database:", connection.database)
        print("Model version ID:", model_version_id)
        print("Assessments processed:", saved_count)

        cursor.execute("""
            SELECT COUNT(*) AS total
            FROM EQUIPMENT_RELIABILITY_ASSESSMENT
            WHERE model_version_id = %s
        """, (model_version_id,))

        count_result = cursor.fetchone()

        print(
            "Assessments stored for this model version:",
            count_result["total"]
        )

    except Exception:
        connection.rollback()
        raise

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()
