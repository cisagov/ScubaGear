# OSCAL Models
See [Layers and Models](https://pages.nist.gov/OSCAL/resources/concepts/layer/) for more in-depth details about the models. Decripions of how the models might pertain to SCuBA follow.

## Catalog Model
NIST has published SP 800-53 in OSCAL form. See [SP800-53](https://github.com/usnistgov/oscal-content/tree/main/nist.gov/SP800-53/). The JSON version of SP 800-53 rev. 5 is also included in the [exemplars](/oscal/exemplars) folder of this repo for convenience.

The SCuBA baselines can also be expressed as an OSCAL catalog. See https://github.com/buidav/scubaTest/tree/main for a
proof of concept.

## Profile
The [create_profile.py](/oscal/create_profile.py) script creates a SCuBA profile of the NIST SP 800-53; essentially, this lists the subset of the
NIST SP 800-53 controls that map to SCuBA controls. Note that this is just a proof of concept and relies on an
incomplete [NIST to SCuBA mapping](/oscal/scuba_mapping.json).

## Component Model
TODO

## System Security Plan Model
TODO

## Assessment Plan Model
The [convert_to_oscal.py](/oscal/convert_to_oscal.py) script takes as input the json file output by ScubaGear and
produces a security assessment plan model (saved as sap.json). Note that there is significant hand-waving here, as in
reality you can't have an assessment plan model without implementing all the preceeding layers.

## Assessment Plan Model
The [convert_to_oscal.py](/oscal/convert_to_oscal.py) script takes as input the json file output by ScubaGear and
produces a security assessment results model (saved as sar.json). Note that there is significant hand-waving here, as in
reality you can't have an assessment plan model without implementing all the preceeding layers.

## Plan of Actions and Milestones
TODO

# Validating OSCAL files
See [How to Validate OSCAL](https://github.com/usnistgov/OSCAL/blob/main/README_validations.md) for the offical
instructions on validating OSCAL. Some pointers:
- The schemas can be hard to find. Some of them are included here in the [schemas folder](/oscal/schemas) for
convenience. See [Other Resources](#other-resources) for the sources.
- NIST recommends using [ajv-cli](https://github.com/ajv-validator/ajv-cli) to validate json version of OSCAL models
- ajv relies on node.
- If you don't already have node installed, see [Download Node.js](https://nodejs.org/en/download/package-manager).
- After you have node installed, run `npm install -g ajv-formats ajv-cli` to install ajv.

Example usage:
```
ajv validate -s .\oscal_assessment-results_schema.json -d .\sar.json -c ajv-formats
```

# Converting JSON to XML
Supposedly, the JSON and XML versions of OSCAL are equivalent, but some tools only accept one or the other.

NIST only publishes a [tool](https://pages.nist.gov/oscal-tools/demos/csx/format-converter/fromjson/) for converting the catalog to XML. Support for the other models is "coming soon."

See [Converting OSCAL JSON Content to XML](https://github.com/usnistgov/OSCAL/tree/4f02dac6f698efda387cc5f55bc99581eaf494b6/build#converting-oscal-json-content-to-xml) for the official instructions on how to convert any model from JSON to XML. Some pointers:
- You can download the jar for saxon here: https://www.saxonica.com/download/java.xml. Select SaxonJ-HE 12.5.
- The XSL files are hard to find. The XSL files for the assessment plan and assessment results are included here in the [xsl](/oscal/xsl) folder for convenience. See [Other Resources](#other-resources) for the sources.

Example usage:
```
java -jar "SaxonHE12-5J\saxon-he-12.5.jar" -xsl:"oscal_assessment-results_json-to-xml-converter.xsl" -o:"sar.xml" -it:from-json file="sar.json"
```

# Other Resources
The authoritative sources for the schemas and converter files:
- [OSCAL Control Layer: Catalog Model](https://pages.nist.gov/OSCAL/resources/concepts/layer/control/catalog/)
- [OSCAL Control Layer: Profile Model](https://pages.nist.gov/OSCAL/resources/concepts/layer/control/profile/)
- [OSCAL Assessment Layer: Assessment Plan Model](https://pages.nist.gov/OSCAL/resources/concepts/layer/assessment/assessment-plan/)
- [OSCAL Assessment Layer: Assessment Results Model](https://pages.nist.gov/OSCAL/resources/concepts/layer/assessment/assessment-results/)
