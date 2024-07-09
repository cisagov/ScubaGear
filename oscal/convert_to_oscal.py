# Refer to https://pages.nist.gov/OSCAL-Reference/models/v1.1.2/assessment-results/json-reference/
#
# To validate:
# ajv validate -s .\oscal_assessment-results_schema.json -d .\results_oscal.json -c ajv-formats
# See https://github.com/usnistgov/OSCAL/blob/main/README_validations.md

import os
import json
import uuid
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("input")
parser.add_argument("output")
args = parser.parse_args()

with open(args.input, 'r', encoding='utf-8-sig') as f:
    results = json.load(f)

# The props sections are where we have freedom to add custom values.
# If you define your own value, you need to specify a unique namespace, "ns",
# for those custom values. The name space needs to be a URI. I'm assuming we'd
# want to document our namespace at that URI? Per the specs, "The organization is
# responsible for defining, managing, and communicating all names...defined and
# tagged with the above name space identifier." I put a Github markdown page,
# that seems like a natural location for this. Though maybe actually publishing
# something isn't required. All the examples I can find from NIST result in 301,
# Moved Permanently.
# TODO open questions 1) what to use as our namespace 2) do we actually need to
# publish something at that URI
NAME_SPACE = "https://github.com/cisagov/ScubaGear/tree/oscal-exploration/oscal/ns/"

#
# Save the locations
#
locations = []
for tenant in results['Raw']['tenant_details']:
    if tenant['DisplayName'] == results['MetaData']['DisplayName']:
        location = {
            "uuid": str(uuid.uuid4()),
            "title": results['MetaData']['DisplayName'],
            "address": {
                "type": "work",
                "addr-lines": [tenant['AADAdditionalData']['Street']],
                "city": tenant['AADAdditionalData']['City'],
                "state": tenant['AADAdditionalData']['State'],
                "country": tenant['AADAdditionalData']['CountryLetterCode'],
                "postal-code": tenant['AADAdditionalData']['PostalCode']
            },
            "remarks": "The location of the M365 tenant."
        }
    locations.append(location)

#
# Initialize the OSCAL data structure
#
oscal = {
    "assessment-results": {
        "uuid": str(uuid.uuid4()),
        "metadata": {
            "title": f"{results['MetaData']['DisplayName']} SCuBA M365 Baseline Assesment Results",
            "published": results['MetaData']['TimestampZulu'],
            "last-modified": results['MetaData']['TimestampZulu'],
            "version": f"{results['MetaData']['Tool']} {results['MetaData']['ToolVersion']}",
            "oscal-version": "1.1.2",
            "props": [
                {
                    "name": "marking",
                    # Real agency data would probably be CUI. Should that be the default marking?
                    # Or should it be something that ScubaConnect adds?
                    # Should ScubaGear omit this field by default but allow it to be specified as a parameter?
                    # TODO open question
                    "value": "Controlled Unclassified Information"
                },
                {
                    "name": "TenantId",
                    "ns": NAME_SPACE,
                    "value": results['MetaData']['TenantId']
                },
                {
                    "name": "DisplayName",
                    "ns": NAME_SPACE,
                    "value": results['MetaData']['DisplayName']
                },
                {
                    "name": "DomainName",
                    "ns": NAME_SPACE,
                    "value": results['MetaData']['DomainName']
                }
            ],
            "roles": [
                {
                    "id": "prepared-for",
                    "title": results['MetaData']['DisplayName'],
                    "description": "The display name of the M365 tenant being assessed by ScubaGear."
                },
                {
                    # The value I put here is dependent on data inserted by ScubaConnect. Is that ok?
                    # TODO open question
                    # If CISA ran this as part of ScubaConnect, should it say prepared-by CISA here?
                    # Should it just say "ScubaGear v1.3.0 instead?"
                    # TODO open question
                    "id": "prepared-by",
                    "title": f"{results['MetaData']['AgencyName']}, {results['MetaData']['SubAgencyName']}",
                    "description": "The entity that ran ScubaGear"
                }
            ],
            "locations": locations
        }
    }
}

# Do we need to include "parties" and "responsible-parties"? TODO open question

# Reference the the SAP, described in the back-matter
sap_uuid = str(uuid.uuid4())
oscal['assessment-results']['import-ap'] = {
    'href': f'#{sap_uuid}'
}

# local-definitions? TODO open question. Looks like they include a lot of SAP stuff in the template. Why?
# This is the SAR after all.


#
# Add the results section
#
oscal['assessment-results']['results'] = []
for product in results['MetaData']['ProductsAssessed']:
    product_uuid = str(uuid.uuid4())
    product_abbr = results['MetaData']['ProductAbbreviationMapping'][product]

    observations = []
    findings = []
    excluded_controls = []

    # TODO can we save the group info somewhere?
    for group in results['Results'][product_abbr]:
        for control in group['Controls']:
            if 'Not-Implemented' not in control['Criticality']:
                observation_uuid = str(uuid.uuid4())
                observations.append({
                    'uuid': observation_uuid,
                    'title': f"Test {control['Control ID']}",
                    # TODO What about links that are embeded in the Details column?
                    # e.g., 0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>
                    'description': control['Details'],
                    'methods': ["Test"],
                    'types': ['statement-objective'],
                    'collected': results['MetaData']['TimestampZulu']
                    # 'origins' TODO
                    # 'related-tasks' TODO
                    # 'relevant-evidence' TODO In an ideal world, I think we would refer to the appropriate section
                    # of the raw output. Relatedly, can/should we include the raw provider output somewhere?
                })
                findings.append({
                    'uuid': str(uuid.uuid4()),
                    'title': control['Control ID'],
                    'description': control['Details'],
                    'target': {
                        "type": "statement-id",
                        'target-id': control['Control ID'],
                        'props': [
                            {
                                "name": "requirement",
                                "ns": NAME_SPACE,
                                "value": control['Requirement'].replace('\n', ' ').strip()
                                # without the above replace.strip, this control:
                                # "At a minimum, the following alerts SHALL be enabled:\na. <b>Suspicious email sending
                                # patterns detected.</b>\nb. <b>Suspicious Connector Activity.</b>\nc. <b>Suspicious
                                # Email Forwarding Activity.</b>\nd. <b>Messages have been delayed.</b>\ne. <b>Tenant restricted from sending unprovisioned email.</b>\nf. <b>Tenant restricted from sending
                                # email.</b>\ng. <b>A potentially malicious URL click was detected.</b>\n<!--Policy:
                                # MS.EXO.16.1v1; Criticality: SHALL -->"
                                #
                                # apparently results in invalid oscal, 'must match pattern "^\\S(.*\\S)?$"'
                                # AKA, a non-empty string with no leading or trailing whitespace. Which I think that
                                # string is? It seems like the \n caused problems for whatever reason.
                            }
                        ],
                        'status': {
                            "state": "satisfied" if control['Result']=='Pass' else "not-satisfied"
                        }
                    },
                    'related-observations': [
                        {
                            'observation-uuid': observation_uuid
                        }
                    ]
                })
            else:
                excluded_controls.append({'control-id': control["Control ID"]})
    result = {
        "uuid": str(uuid.uuid4()),
        "title": f"SCuBA M365 {product} Baseline Assesment Results",
        "description": f"Results of assessment performed by ScubaGear for the {product} baseline",
        "start": results['MetaData']['TimestampZulu'],
        "end": results['MetaData']['TimestampZulu'],
        "local-definitions": {
            # A remark in the example SAR says that ideally all assessment platforms and components
            # would be defined in the SAP, but we can define them here. Would we want to include
            # them here? TODO open question
            "assessment-assets": {
                # "components": [
                #     {
                #         "uuid": product_uuid,
                #         # Not sure what to put here for "type". TODO open question
                #         "type": "SaaS offering",
                #         "title": product_abbr,
                #         "description": product
                #     }
                # ],
                "assessment-platforms": [
                    {
                        # Should ScubaGear has the same UUID between runs? Or maybe it changes with each new
                        # release? Or is a new random value per run ok? TODO open question.
                        "uuid": str(uuid.uuid4()),
                        "title": results['MetaData']['Tool'],
                        "uses-components": [
                            {
                                "component-uuid": product_uuid
                            }
                        ],
                        "props": [
                            {
                                "name": "version",
                                "ns": NAME_SPACE,
                                "value": results['MetaData']['ToolVersion']
                            }
                        ]
                    }
                ]
            }
        },
        "reviewed-controls": {
            "control-selections": [
                {
                    "description": f"Include all controls in the {product} baseline, except those that cannot be \
                        checked via ScubaGear.", # TODO also exclude those excluded via config file, once that feature
                        # is complete
                    "include-all": {}
                }
            ],
            "control-objective-selections": [
            {
              "include-all": {}
            }
          ]
        },
        # TODO attestations
        "assessment-log": {
            "entries": [
                {
                    "uuid": str(uuid.uuid4()),
                    "title": "Run ScubaGear",
                    "start": results['MetaData']['TimestampZulu'],
                    "end": results['MetaData']['TimestampZulu']
                }
            ]
        },
        'observations': observations,
        "findings": findings
        # TODO risks
    }
    if len(excluded_controls) > 0:
        result['reviewed-controls']['control-selections'][0]['exclude-controls'] = excluded_controls

    oscal['assessment-results']['results'].append(result)



# Generate a relative path from the location of the OSCAL output the json input
output_folder = os.path.dirname(args.output)
relative_path = os.path.relpath(output_folder, args.input)
input_fname = os.path.basename(args.input)
path_to_raw = os.path.join(relative_path, input_fname).replace('\\', '/')

# Add back-matter
oscal['assessment-results']['back-matter'] = {
    'resources': [
        {
            'uuid': sap_uuid,
            'title': "TODO",
            'props': [
                {
                    'name': 'type',
                    'value': 'security-assessment-plan'
                },
                {
                    'name': 'published',
                    'value': 'TODO'
                },
                {
                    'name': 'version',
                    'value': 'TODO'
                }
            ]
        },
        {
            "uuid": str(uuid.uuid4()),
            "title": "ScubaGear Github repository",
            'rlinks': [
                {
                    "href": "https://github.com/cisagov/ScubaGear",
                    "media-type": "text/html"
                }
            ]
        },
        {
            "uuid": str(uuid.uuid4()),
            "title": "Raw ScubaGear output",
            'rlinks': [
                {
                    "href": path_to_raw,
                    "media-type": "text/json"
                }
            ]
        }
    ]
}

with open(args.output, 'w', encoding='utf-8') as f:
    json.dump(oscal, f, indent=4)