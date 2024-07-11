# Refer to https://pages.nist.gov/OSCAL-Reference/models/v1.1.2/assessment-results/json-reference/
# and https://pages.nist.gov/OSCAL-Reference/models/v1.1.2/assessment-plan/json-reference/
#
# To validate:
# ajv validate -s .\oscal_assessment-results_schema.json -d .\sar.json -c ajv-formats
# or
# ajv validate -s .\oscal_assessment-results_schema.json -d .\sar.json -c ajv-formats
#
# See https://github.com/usnistgov/OSCAL/blob/main/README_validations.md

# To convert to xml:
# java -jar "SaxonHE12-5J\saxon-he-12.5.jar" -xsl:"oscal_assessment-results_json-to-xml-converter.xsl" -o:"sar.xml" -it:from-json file="sar.json"
# download the jar here: https://www.saxonica.com/download/java.xml

import os
import json
import uuid
import argparse
from datetime import datetime

parser = argparse.ArgumentParser()
parser.add_argument("input")
args = parser.parse_args()

with open(args.input, 'r', encoding='utf-8-sig') as f:
    raw_results = json.load(f)

####################
# Define constants #
####################

OSCAL_VERSION = "1.1.2"

SSP_UUID = str(uuid.uuid4())
SSP_TITLE = f"{raw_results['MetaData']['DisplayName']} SCuBA M365 Baseline System Security Plan"

SAP_UUID = str(uuid.uuid4())
SAP_TITLE = f"{raw_results['MetaData']['DisplayName']} SCuBA M365 Baseline Assesment Plan"

LAST_MODIFIED = datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%fZ')

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

# Per https://pages.nist.gov/OSCAL-Reference/models/v1.1.2/assessment-plan/json-reference/#/assessment-plan/assessment-assets/assessment-platforms/uuid
# the assessment assets have per-subject consistency,
# (see https://pages.nist.gov/OSCAL/resources/concepts/identifier-use/#consistency)
# meaning it "should only be changed if the underlying identified subject has changed
# in a significant way that no longer represents the same identified subject."
POWERSHELL_UUID = '5b6e9b9e-828d-49ab-8767-5b82b63ee505'
REGO_UUID = '6628dfaf-cacf-48d2-bbe9-b551b31b400d'
SCUBAGEAR_UUID = '8b420415-a7cb-4cea-84d3-c691a2e19225'

OUTPUT_FOLDER = os.path.dirname(args.input)

##################
# Create the SAP #
##################

# Initialize the SAP structure
sap = {"assessment-plan": {}}

# Save the UUID
sap['assessment-plan']['uuid'] = SAP_UUID

# Define the roles
roles = [
    {
        "id": "prepared-for",
        "title": raw_results['MetaData']['DisplayName'],
        "description": "The display name of the M365 tenant being assessed by ScubaGear."
    },
    {
        "id": "prepared-by",
        # TODO this should probably be a person/org, not the tool
        "title": f"{raw_results['MetaData']['Tool']} {raw_results['MetaData']['ToolVersion']}"
    }
]

# Save the metadata
sap['assessment-plan']["metadata"] = {
    "title": SAP_TITLE,
    "last-modified": LAST_MODIFIED,
    "version": f"{raw_results['MetaData']['Tool']} {raw_results['MetaData']['ToolVersion']}",
    "oscal-version": OSCAL_VERSION,
    "roles": roles
}

# Save a reference to the SSP
sap['assessment-plan']['import-ssp'] = {
    "href": f"#{SSP_UUID}"
}

# Save the control selections
sap['assessment-plan']['reviewed-controls'] = {}
sap['assessment-plan']['reviewed-controls']['control-selections'] = []
for product in raw_results['MetaData']['ProductsAssessed']:
    selection = {
        "description": f"Include all controls in the {product} baseline, except those that cannot be" \
            "checked via ScubaGear.", # TODO also exclude those excluded via config file, once that feature is complete
        "include-all": {}
    }
    excluded_controls = []
    product_abbr = raw_results['MetaData']['ProductAbbreviationMapping'][product]
    for group in raw_results['Results'][product_abbr]:
        for control in group['Controls']:
            if 'Not-Implemented' in control['Criticality']:
                excluded_controls.append({'control-id': control["Control ID"]})
    if len(excluded_controls) > 0:
        selection['exclude-controls'] = excluded_controls
    sap['assessment-plan']['reviewed-controls']['control-selections'].append(selection)

# Save the control objective selections
# TODO I'm not completely confident on the difference between control-selections and control-objective-selections
sap['assessment-plan']['reviewed-controls']['control-objective-selections'] = [ {"include-all": {}} ]

# Save the assessment subjects
sap['assessment-plan']['assessment-subjects'] = []

# Add the M365 tenant itself as a subject
sap['assessment-plan']['assessment-subjects'].append({
    # TODO type component means it's been definded as a component inthe SSP, which hasn't been written yet
    # Once it has been written many of these details might be moved there
    "type": "component",
    # "title": "M365 tenant",
    "description": "The M365 tenant being assessed.",
    "props": [
        {
            "name": "TenantId",
            "ns": NAME_SPACE,
            "value": raw_results['MetaData']['TenantId']
        },
        {
            "name": "DisplayName",
            "ns": NAME_SPACE,
            "value": raw_results['MetaData']['DisplayName']
        },
        {
            "name": "DomainName",
            "ns": NAME_SPACE,
            "value": raw_results['MetaData']['DomainName']
        }
    ]
})

# Add the individual products as components
for product in raw_results['MetaData']['ProductsAssessed']:
    sap['assessment-plan']['assessment-subjects'].append({
        # TODO type component means this has been defined in the SSP
        "type": "component",
        "description": product
    })

# Assessment assets
sap['assessment-plan']['assessment-assets'] = {}

sap['assessment-plan']['assessment-assets']['components'] = []
sap['assessment-plan']['assessment-assets']['components'].append({
    "uuid": POWERSHELL_UUID,
    "type": "software",
    "title": "PowerShell",
    "description": "The PowerShell scripting language.",
    "status": {
        "state": "operational"
    }
})
sap['assessment-plan']['assessment-assets']['components'].append({
    "uuid": REGO_UUID,
    "type": "software",
    "title": "OPA Rego",
    "description": "Rego is a query language designed for evaluating policy.",
    "status": {
        "state": "operational"
    }
})

sap['assessment-plan']['assessment-assets']['assessment-platforms'] = []
sap['assessment-plan']['assessment-assets']['assessment-platforms'].append({
        "uuid": SCUBAGEAR_UUID,
        "title": raw_results['MetaData']['Tool'],
        "props": [
            {
                "name": "version",
                "value": raw_results['MetaData']['ToolVersion']
            }
        ],
        'uses-components': [{'component-uuid': component['uuid']} for component in
            sap['assessment-plan']['assessment-assets']['components']]
})

# Add the tasks
sap['assessment-plan']['tasks'] = [
    {
        "uuid": str(uuid.uuid4()),
        'type': "action",
        "title": "Run ScubaGear"
    }
]

# Backmatter
sap['assessment-plan']['back-matter'] = { "resources": [] }

sap['assessment-plan']['back-matter']['resources'].append({
    'uuid': SSP_UUID,
    'title': SSP_TITLE,
    'props': [
        {
            'name': 'type',
            'value': 'system-security-plan'
        }
    ],
    'rlinks': [
        {
            "href": f"./ssp.json",
            "media-type": "text/json"
        }
    ]
})

sap['assessment-plan']['back-matter']['resources'].append({
    "uuid": str(uuid.uuid4()),
    "title": "ScubaGear Github repository",
    'rlinks': [
        {
            "href": "https://github.com/cisagov/ScubaGear",
            "media-type": "text/html"
        }
    ]
})

# Save the SAP
with open(os.path.join(OUTPUT_FOLDER, "sap.json"), 'w', encoding='utf-8') as f:
    json.dump(sap, f, indent=4)


##################
# Create the SAR #
##################

# Define the locations
locations = []
for tenant in raw_results['Raw']['tenant_details']:
    if tenant['DisplayName'] == raw_results['MetaData']['DisplayName']:
        location = {
            "uuid": str(uuid.uuid4()),
            "title": raw_results['MetaData']['DisplayName'],
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

# Initialize the SAR data structure
sar = { "assessment-results": {} }

# Add the uuid
sar['assessment-results']['uuid'] = str(uuid.uuid4())

# Add the metadata
sar["assessment-results"]["metadata"] = {
    "title": f"{raw_results['MetaData']['DisplayName']} SCuBA M365 Baseline Assesment Results",
    "published": raw_results['MetaData']['TimestampZulu'],
    "last-modified": LAST_MODIFIED,
    "version": f"{raw_results['MetaData']['Tool']} {raw_results['MetaData']['ToolVersion']}",
    "oscal-version": OSCAL_VERSION,
    "roles": roles,
    "locations": locations
}

# Reference the the SAP
# The "#" before the uuid tells you to look for that UUID
# elsewhere in the SAR for details on where to find the SAP
sar['assessment-results']['import-ap'] = {
    'href': f'#{SAP_UUID}'
}

# Add the results section
sar['assessment-results']['results'] = []
for product in raw_results['MetaData']['ProductsAssessed']:
    product_uuid = str(uuid.uuid4())
    product_abbr = raw_results['MetaData']['ProductAbbreviationMapping'][product]

    observations = []
    findings = []
    excluded_controls = []

    # TODO can we save the group info somewhere?
    for group in raw_results['Results'][product_abbr]:
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
                    'collected': raw_results['MetaData']['TimestampZulu']
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
        "start": raw_results['MetaData']['TimestampZulu'],
        "end": raw_results['MetaData']['TimestampZulu'],
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
                    "start": raw_results['MetaData']['TimestampZulu'],
                    "end": raw_results['MetaData']['TimestampZulu']
                }
            ]
        },
        'observations': observations,
        "findings": findings
        # TODO risks
    }
    if len(excluded_controls) > 0:
        result['reviewed-controls']['control-selections'][0]['exclude-controls'] = excluded_controls

    sar['assessment-results']['results'].append(result)



# Generate a relative path from the location of the SAR file the json file
input_fname = os.path.basename(args.input)
path_to_raw = f"./{input_fname}"

# Add back-matter
sar['assessment-results']['back-matter'] = { "resources": [] }
sar['assessment-results']['back-matter']['resources'].append({
    'uuid': SAP_UUID,
    'title': SAP_TITLE,
    'props': [
        {
            'name': 'type',
            'value': 'security-assessment-plan'
        }
    ],
    'rlinks': [
        {
            "href": f"./sap.json",
            "media-type": "text/json"
        }
    ]
})

sar['assessment-results']['back-matter']['resources'].append({
    "uuid": str(uuid.uuid4()),
    "title": "ScubaGear Github repository",
    'rlinks': [
        {
            "href": "https://github.com/cisagov/ScubaGear",
            "media-type": "text/html"
        }
    ]
})

sar['assessment-results']['back-matter']['resources'].append({
    "uuid": str(uuid.uuid4()),
    "title": "Raw ScubaGear output",
    'rlinks': [
        {
            "href": path_to_raw,
            "media-type": "text/json"
        }
    ]
})

with open(os.path.join(OUTPUT_FOLDER, "sar.json"), 'w', encoding='utf-8') as f:
    json.dump(sar, f, indent=4)