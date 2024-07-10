import json
import uuid
from datetime import datetime

OSCAL_VERSION = "1.1.2"
SCUBA_VERSION = "1.3.0"
LAST_MODIFIED = datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%fZ')
CISA_UUID = str(uuid.uuid4())
CATALOG_UUID = str(uuid.uuid4())

# This mapping is NOT complete yet, but good enough for proof of concept
with open("scuba_mapping.json", 'r') as f:
    scuba_mapping = json.load(f)
included_controls = []
for scuba_control in scuba_mapping:
    included_controls.extend(scuba_mapping[scuba_control])

# Initialize the profile structure
profile = { "profile": {} }

# Save the UUID
profile['profile']['uuid'] = str(uuid.uuid4())

# Save the basic metadata
profile['profile']['metadata'] = {
    'title': f"NIST Special Publication 800-53 Revision 5 SCuBA M365 {SCUBA_VERSION} Profile",
    'last-modified': LAST_MODIFIED,
    'version': SCUBA_VERSION,
    'oscal-version': OSCAL_VERSION
}

# Save the roles metadata
profile['profile']['metadata']['roles'] = []
profile['profile']['metadata']['roles'].append({
    "id": "creator",
    "title": "Document Creator"
})
profile['profile']['metadata']['roles'].append({
    "id": "contact",
    "title": "Contact"
})

# Save the parties metadata
profile['profile']['metadata']['parties'] = []
profile['profile']['metadata']['parties'].append({
    "uuid": CISA_UUID,
    "type": "organization",
    "name": "Cybersecurity and Infrastructure Security Agency",
    "email-addresses": [ "CyberSharedServices@cisa.dhs.gov" ]
})

# Save the responsible parties metadata
profile['profile']['metadata']['responsible-parties'] = []
profile['profile']['metadata']['responsible-parties'].append({
    'role-id': "creator",
    "party-uuids": [ CISA_UUID ]
})
profile['profile']['metadata']['responsible-parties'].append({
    'role-id': "contact",
    "party-uuids": [ CISA_UUID ]
})

# Add the imports
profile['profile']['imports'] = []
profile['profile']['imports'].append({
    "href": f"#{CATALOG_UUID}",
    "include-controls": [ { "with-ids": included_controls } ]
})

# Add merge directive
profile['profile']['merge'] = {
    'as-is': True
}

# Save the backmatter
profile['profile']['back-matter'] = {}
profile['profile']['back-matter']['resources'] = []
profile['profile']['back-matter']['resources'].append({
    "uuid": CATALOG_UUID,
    "description": "NIST Special Publication 800-53 Revision 5: "\
        "Security and Privacy Controls for Federal Information Systems and Organizations",
    "rlinks": [
        {
            "href": "./NIST_SP-800-53_rev5_catalog.json",
            "media-type": "application/oscal.catalog+json"
        },
    ]
})

# Save the resulting profile
with open("NIST_SP-800-53_rev5_M365-SCuBA_profile.json", 'w') as f:
    json.dump(profile, f, indent=4)