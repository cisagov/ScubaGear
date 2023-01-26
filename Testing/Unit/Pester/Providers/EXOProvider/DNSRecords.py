from checkdmarc import *

from dns.resolver import Resolver
import sys

def getDMARC(domain, res):
    try:
        dmarc = query_dmarc_record(domain, resolver=res)
        print(dmarc['record'])
    except DMARCRecordNotFound:
        print("")

def getSPF(domain, res):
    try:
        spf = query_spf_record(domain, resolver=res)
        print(spf['record'])
    except SPFRecordNotFound:
        print("")

def getDKIM(domain, res):
    selectors = ["selector1", "selector2", f"selector1.{domain}".replace("\.", "-"), f"selector2.{domain}".replace("\.", "-")]
    answers = []
    for selector in selectors:
        try:
            response = res.resolve(f"{selector}._domainkey.{domain}", "TXT")
            for answer in response:
                for s in answer.strings:
                    answers.append(s.decode("utf-8"))
        except:
            pass
    print(answers)

def main():

    domain = sys.argv[1]
    rec_type = sys.argv[2]

    res = Resolver()
    res.nameservers = ['1.1.1.1']

    if rec_type == "dmarc":
        getDMARC(domain, res)
    elif rec_type == "spf":
        getSPF(domain, res)
    else:
        print("Unknown type:", rec_type)

if __name__ == "__main__":
    main()
