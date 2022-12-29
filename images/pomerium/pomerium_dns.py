import CloudFlare, re, sys, requests

def main():
    f = open(sys.argv[1])
    config_file = f.readlines()
    f.close()

    public_ip = requests.get("http://wtfismyip.com/text").text
    
    dns_records = []
    for line in config_file:
        domain_search = re.search('.+from.+https:\/\/(.+).devusb.us', line, re.IGNORECASE)
        if domain_search:
            dns_records.append({'name':domain_search.group(1), 'type':'CNAME', 'content':'devusb.us', 'proxied':True})
    
    cf = CloudFlare.CloudFlare()
    zone_name = 'devusb.us'
    r = cf.zones.get(params={'name': zone_name})
    zone_id = r[0]['id']
    
    for dns_record in dns_records:
        # Create DNS record
        try:
            r = cf.zones.dns_records.post(zone_id, data=dns_record)
        except CloudFlare.exceptions.CloudFlareAPIError as e:
            print('/zones.dns_records.post %s %s - %d %s' % (zone_name, dns_record['name'], e, e))
            continue
        # Print respose info - they should be the same
        dns_record = r
        print('\t%s %30s %6d %-5s %s ; proxied=%s proxiable=%s' % (
            dns_record['id'],
            dns_record['name'],
            dns_record['ttl'],
            dns_record['type'],
            dns_record['content'],
            dns_record['proxied'],
            dns_record['proxiable']
        ))

if __name__ == '__main__':
    main()
