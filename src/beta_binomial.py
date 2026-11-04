
from scipy.stats import beta


class BetaBinomialModel:

    def __init__(self, alpha=1.0, beta_param=1.0):

        if alpha <= 0 or beta_param <= 0:
            raise ValueError("Prior parameters must be positive.")

        self.alpha = alpha
        self.beta_param = beta_param

    def fit(self, failures, total_observations):

        if failures < 0 or total_observations < 0:
            raise ValueError("Observation counts cannot be negative.")

        if failures > total_observations:
            raise ValueError("Failures cannot exceed total observations.")

        passed = total_observations - failures

        posterior_alpha = self.alpha + failures
        posterior_beta = self.beta_param + passed

        mean_failure_probability = (
            posterior_alpha /
            (posterior_alpha + posterior_beta)
        )

        mean_reliability = 1 - mean_failure_probability

        lower_bound = beta.ppf(
            0.025, posterior_alpha, posterior_beta
        )

        upper_bound = beta.ppf(
            0.975, posterior_alpha, posterior_beta
        )

        return {
            "prior_alpha": self.alpha,
            "prior_beta": self.beta_param,
            "posterior_alpha": posterior_alpha,
            "posterior_beta": posterior_beta,
            "mean_failure_probability": mean_failure_probability,
            "mean_reliability": mean_reliability,
            "failure_probability_ci_lower": lower_bound,
            "failure_probability_ci_upper": upper_bound
        }
