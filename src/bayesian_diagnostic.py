
class BayesianDiagnosticModel:
    """
    Estimate disease probability after a diagnostic test result.

    Parameters are illustrative and must be replaced with
    documented test-performance estimates before research use.
    """

    def __init__(self, prevalence, sensitivity, specificity):

        parameters = {
            "prevalence": prevalence,
            "sensitivity": sensitivity,
            "specificity": specificity
        }

        for name, value in parameters.items():

            if not 0 <= value <= 1:
                raise ValueError(
                    f"{name} must be between 0 and 1."
                )

        if prevalence == 0 or prevalence == 1:
            raise ValueError(
                "Prevalence must be strictly between 0 and 1."
            )

        self.prevalence = prevalence
        self.sensitivity = sensitivity
        self.specificity = specificity

    def calculate(self, test_result):

        if test_result not in ("Positive", "Negative"):
            raise ValueError(
                "Test result must be Positive or Negative."
            )

        prevalence = self.prevalence
        sensitivity = self.sensitivity
        specificity = self.specificity

        if test_result == "Positive":

            numerator = sensitivity * prevalence

            denominator = (
                sensitivity * prevalence
                + (1 - specificity) * (1 - prevalence)
            )

        else:

            numerator = (1 - sensitivity) * prevalence

            denominator = (
                (1 - sensitivity) * prevalence
                + specificity * (1 - prevalence)
            )

        if denominator == 0:
            raise ValueError(
                "Posterior probability is undefined."
            )

        posterior_probability = numerator / denominator

        return {
            "test_result": test_result,
            "prevalence": prevalence,
            "sensitivity": sensitivity,
            "specificity": specificity,
            "posterior_probability": posterior_probability
        }
