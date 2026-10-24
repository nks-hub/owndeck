import unittest

from telemetry_config import configuration


class TelemetryConfigurationTest(unittest.TestCase):
    def setUp(self):
        self.values = {
            "SENTRY_DSN": "https://publickey@sentry.example.com/42",
            "RYBBIT_HOST": "https://analytics.example.com",
            "RYBBIT_SITE_ID": "site42",
        }

    def test_official_configuration_requires_both_services(self):
        for key in self.values:
            with self.subTest(key=key), self.assertRaises(ValueError):
                configuration(self.values | {key: ""}, "0.1.0+1")

    def test_release_is_derived_from_the_repository_version(self):
        result = configuration(self.values, "0.1.0+1")
        self.assertEqual(result["TELEMETRY_RELEASE"], "com.nkshub.nextclouddeck@0.1.0+1")
        self.assertEqual(result["TELEMETRY_ENVIRONMENT"], "production")

    def test_rejects_non_https_credentials_and_query_strings(self):
        for key, value in [
            ("SENTRY_DSN", "http://publickey@sentry.example.com/42"),
            ("SENTRY_DSN", "https://key:password@sentry.example.com/42"),
            ("RYBBIT_HOST", "https://user@analytics.example.com"),
            ("RYBBIT_HOST", "https://analytics.example.com/?token=private"),
            ("RYBBIT_SITE_ID", "site/private"),
        ]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                configuration(self.values | {key: value}, "0.1.0+1")

    def test_rejects_untrusted_environment_and_release_text(self):
        with self.assertRaises(ValueError):
            configuration(self.values | {"TELEMETRY_ENVIRONMENT": "private-account"}, "0.1.0+1")
        with self.assertRaises(ValueError):
            configuration(self.values, "https://private.example.com")


if __name__ == "__main__":
    unittest.main()
