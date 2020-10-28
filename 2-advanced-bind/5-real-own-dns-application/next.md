TOOO:

Part A, B and vlc concluded
side not on gtm end of part b 


y. configure own DHC server


3. Use IPv6 
http://192.168.1.1/networkv6/firewall
https://stackoverflow.com/questions/25817848/python-3-does-http-server-support-ipv6
https://superuser.com/questions/367780/how-to-connect-to-a-website-that-has-only-ipv6-addresses-without-a-domain-name
https://superuser.com/questions/236993/how-to-ssh-to-a-ipv6-ubuntu-in-a-lan
https://wiki.videolan.org/Documentation:Streaming_HowTo/Streaming_over_IPv6/
seee  AAAA

even  dns v6 to work offline (gtm)
use dns  + dhcp v6

4. We used internal DNS router (Internet Box) override for traffic switch between public and private IP.
(not go outside to get inside).
It avoids going outside for traffic + DNS resolution
This approach is working for Gandi and own DNS, we  show how to use DNS view when we have our own nameserver to perform the switch using bind views.


Update ref here part c## DNS resolution is also made internally when on same LAN and using router DNS

- Could prepare a DNS presentation with this 

For demo could make more sense to perform domain delegation, but fine if updated before.
It would be the same principle!
DNS demo with AWS already in [AWS demo and here show docker

5. See [next priv](./next_private.md)

- Misc
    - check 2 cname with same name
    - when several A round robin
    - access hue outside    
    - android tools ok
    
[NEXT IS COMPLETE 28 oct 21h40] OKOK