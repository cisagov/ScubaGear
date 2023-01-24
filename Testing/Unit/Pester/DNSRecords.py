from checkdmarc import *

from dns.resolver import Resolver
import sys

def getDMARC(domain, res):
    try:
        dmarc = query_dmarc_record(domain, resolver=res)
        print(dmarc['record'])
    except DMARCRecordNotFound:
        print("")

def getSPF():
    pass
    #spf = query_spf_record(domain, resolver=res)
    
    #print(spf)

def getDKIM():
    # help please
    pass


def main():

    domain = sys.argv[1]
    rec_type = sys.argv[2]

    res = Resolver()
    res.nameservers = ['1.1.1.1']


    if rec_type == "dmarc":
        getDMARC(domain, res)
    else:
        getSPF(domain, res)


if __name__ == "__main__":
    main()
