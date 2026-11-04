
import random

from .beta_binomial import BetaBinomialModel


# Reproducible simulation
random.seed(42)

EQUIPMENT_PROFILES = {
    "Reliable": 0.02,
    "Moderate": 0.10,
    "Poor": 0.25
}

SAMPLE_SIZES = [20, 50, 100, 500]
REPETITIONS = 1000


def simulate_qc(true_failure_probability, total_observations):

    failures = sum(
        random.random() < true_failure_probability
        for _ in range(total_observations)
    )

    return failures


def evaluate_model(true_probability, sample_size, repetitions):

    model = BetaBinomialModel()

    posterior_means = []
    interval_widths = []
    coverage_count = 0

    for _ in range(repetitions):

        failures = simulate_qc(
            true_probability,
            sample_size
        )

        result = model.fit(
            failures=failures,
            total_observations=sample_size
        )

        posterior_mean = result["mean_failure_probability"]

        lower = result["failure_probability_ci_lower"]
        upper = result["failure_probability_ci_upper"]

        posterior_means.append(posterior_mean)

        interval_widths.append(upper - lower)

        if lower <= true_probability <= upper:
            coverage_count += 1

    average_estimate = sum(posterior_means) / repetitions

    average_bias = average_estimate - true_probability

    average_interval_width = (
        sum(interval_widths) / repetitions
    )

    empirical_coverage = coverage_count / repetitions

    return {
        "average_estimate": average_estimate,
        "average_bias": average_bias,
        "average_interval_width": average_interval_width,
        "empirical_coverage": empirical_coverage
    }


def run_simulation():

    print("\nBETA-BINOMIAL SAMPLE SIZE EVALUATION")
    print("=" * 105)

    for equipment, true_probability in EQUIPMENT_PROFILES.items():

        print(f"\nEquipment: {equipment}")
        print(f"True failure probability: {true_probability:.2%}")
        print("-" * 105)

        print(
            f"{'Sample':<10}"
            f"{'Mean Estimate':<17}"
            f"{'Bias':<15}"
            f"{'Avg CI Width':<17}"
            f"{'95% CI Coverage':<18}"
        )

        for sample_size in SAMPLE_SIZES:

            result = evaluate_model(
                true_probability=true_probability,
                sample_size=sample_size,
                repetitions=REPETITIONS
            )

            print(
                f"{sample_size:<10}"
                f"{result['average_estimate']:<17.4f}"
                f"{result['average_bias']:<15.4f}"
                f"{result['average_interval_width']:<17.4f}"
                f"{result['empirical_coverage']:<18.2%}"
            )


if __name__ == "__main__":
    run_simulation()
