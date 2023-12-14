package exo_test
import future.keywords
import data.exo
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.PASS


#
# Policy 1
#--
test_Enabled_Correct_V1 if {
    Output := exo.tests with input as {
        "dkim_config": [
            {
                "Enabled": true,
                "Domain": "test.name"
            }
        ],
        "dkim_records": [
            {
                "rdata": [
                    "v=DKIM1;"
                ],
                "domain": "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "test.name"
            }
        ]
    }

    CorrectTestResult("MS.EXO.3.1v1", Output, PASS) == true
}

# Test with correct default domain
test_Enabled_Correct_V2 if {
    Output := exo.tests with input as {
        "dkim_config": [
            {
                "Enabled": true,
                "Domain": "test.name"
            },
            {
                "Enabled": true,
                "Domain": "example.onmicrosoft.com"
            }
        ],
        "dkim_records": [
            {
                "rdata": [
                    "v=DKIM1;"
                ],
                "domain": "test.name"
            },
            {
                "rdata": [
                    "v=DKIM1;"
                ],
                "domain": "example.onmicrosoft.com"
            }
        ],
        "spf_records": [
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "test.name"
            },
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "example.onmicrosoft.com"
            }
        ]
    }

    CorrectTestResult("MS.EXO.3.1v1", Output, PASS) == true
}

# Test for multiple custom domains
test_Enabled_Correct_V3 if {
    Output := exo.tests with input as {
        "dkim_config": [
            {
                "Enabled": true,
                "Domain": "test.name"
            },
            {
                "Enabled": true,
                "Domain": "test2.name"
            }
        ],
        "dkim_records": [
            {
                "rdata": [
                    "v=DKIM1;"
                ],
                "domain": "test.name"
            },
            {
                "rdata": [
                    "v=DKIM1;"
                ],
                "domain": "test2.name"
            }
        ],
        "spf_records": [
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "test.name"
            },
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "test2.name"
            }
        ]
    }

    CorrectTestResult("MS.EXO.3.1v1", Output, PASS) == true
}

# Test for no custom domains, just the default domain
test_Enabled_Correct_V4 if {
    Output := exo.tests with input as {
        "dkim_config": [
            {
                "Enabled": true,
                "Domain": "example.onmicrosoft.com"
            }
        ],
        "dkim_records": [
            {
                "rdata": [
                    "v=DKIM1;"
                ],
                "domain": "example.onmicrosoft.com"
            }
        ],
        "spf_records": [
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "example.onmicrosoft.com"
            }
        ]
    }

    CorrectTestResult("MS.EXO.3.1v1", Output, PASS) == true
}

test_Enabled_Incorrect if {
    Output := exo.tests with input as {
        "dkim_config": [
            {
                "Enabled": false,
                "Domain": "test.name"
            }
        ],
        "dkim_records": [
            {
                "rdata": [
                    "v=DKIM1;"
                ],
                "domain": "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "test.name"
            }
        ]
    }

    ReportDetailString := "1 of 1 agency domain(s) found in violation: test.name"
    IncorrectTestResult("MS.EXO.3.1v1", Output, ReportDetailString) == true
}

test_Rdata_Incorrect_V1 if {
    Output := exo.tests with input as {
        "dkim_config": [
            {
                "Enabled": true,
                "Domain": "test.name"
            }
        ],
        "dkim_records": [
            {
                "rdata": [],
                "domain": "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "test.name"
            }
        ]
    }

    ReportDetailString := "1 of 1 agency domain(s) found in violation: test.name"
    IncorrectTestResult("MS.EXO.3.1v1", Output, ReportDetailString) == true
}

test_Rdata_Incorrect_V2 if {
    Output := exo.tests with input as {
        "dkim_config": [
            {
                "Enabled": true,
                "Domain": "test.name"
            }
        ],
        "dkim_records": [
            {
                "rdata": [
                    "Hello World"
                ],
                "domain": "test.name"
            }
        ],
        "spf_records": [
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "test.name"
            }
        ]
    }

    ReportDetailString := "1 of 1 agency domain(s) found in violation: test.name"
    IncorrectTestResult("MS.EXO.3.1v1", Output, ReportDetailString) == true
}

test_Enabled_Incorrect_V3 if {
    Output := exo.tests with input as {
        "dkim_config": [
            {
                "Enabled": true,
                "Domain": "test.name"
            },
            {
                "Enabled": false,
                "Domain": "test2.name"
            }
        ],
        "dkim_records": [
            {
                "rdata": [
                    "v=DKIM1;"
                ],
                "domain": "test.name"
            },
            {
                "rdata": [
                    "v=DKIM1;"
                ],
                "domain": "test2.name"
            }
        ],
        "spf_records": [
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "test.name"
            },
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "test2.name"
            }
        ]
    }

    ReportDetailString := "1 of 2 agency domain(s) found in violation: test2.name"
    IncorrectTestResult("MS.EXO.3.1v1", Output, ReportDetailString) == true
}

# Test with incorrect default domain
test_Enabled_Incorrect_V4 if {
    Output := exo.tests with input as {
        "dkim_config": [
            {
                "Enabled": true,
                "Domain": "test.name"
            },
            {
                "Enabled": false,
                "Domain": "example.onmicrosoft.com"
            }
        ],
        "dkim_records": [
            {
                "rdata": [
                    "v=DKIM1;"
                ],
                "domain": "test.name"
            },
            {
                "rdata": [],
                "domain": "example.onmicrosoft.com" # this should fail
            }
        ],
        "spf_records": [
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "test.name"
            },
            {
                "rdata": [
                    "spf1 "
                ],
                "domain": "example.onmicrosoft.com"
            }
        ]
    }

    ReportDetailString := "1 of 2 agency domain(s) found in violation: example.onmicrosoft.com"
    IncorrectTestResult("MS.EXO.3.1v1", Output, ReportDetailString) == true
}
#--