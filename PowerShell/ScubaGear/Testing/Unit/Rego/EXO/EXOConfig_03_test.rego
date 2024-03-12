package exo_test
import rego.v1
import data.exo
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.EXO.3.1v1
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

    TestResult("MS.EXO.3.1v1", Output, PASS, true) == true
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

    TestResult("MS.EXO.3.1v1", Output, PASS, true) == true
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

    TestResult("MS.EXO.3.1v1", Output, PASS, true) == true
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

    TestResult("MS.EXO.3.1v1", Output, PASS, true) == true
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

    ReportDetailString := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.3.1v1", Output, ReportDetailString, false) == true
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

    ReportDetailString := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.3.1v1", Output, ReportDetailString, false) == true
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

    ReportDetailString := "1 agency domain(s) found in violation: test.name"
    TestResult("MS.EXO.3.1v1", Output, ReportDetailString, false) == true
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

    ReportDetailString := "1 agency domain(s) found in violation: test2.name"
    TestResult("MS.EXO.3.1v1", Output, ReportDetailString, false) == true
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

    ReportDetailString := "1 agency domain(s) found in violation: example.onmicrosoft.com"
    TestResult("MS.EXO.3.1v1", Output, ReportDetailString, false) == true
}
#--