SSL certificates: brief descriptions

An SSL certificate is needed to operate a web socket securely, or to enable HTTPS communication. Encrypting images is a good idea, so we will use this from the get-go.

How SSL connections generally work:
0) server and client exchange server/client salts
1) server sends the SSL certificate to the client along with a pubic key
2) client generates a pre-master and encrypts it with the public key; it can only be decrypted by the server's private key
3) server recieves and decrypts the pre-master.
4) both the server and client create a shared session key using {pre-master, server-salt, client-salt} in a process called key derivation function (KDF); the shared session key is symmetric (used for both encryption and decryption)
5) all further traffic if encrypted/decrypted with the shared session key.

All of this shit with exchanging salts and such is embedded in the ssl frameworks; the only thing we need to provide as the server is the certificate and key.


NOTE: I will be generating this key TEMPORARILY locally. In the future, if/when we get a domain name, the SSL should be generated with the domain through a Certificate Authority (CA); for now, the local option will do, but the the local option will actually expire after ~1 year.


HOW TO GENERATE LOCAL SSL:

>> openssl req -x509 -newkey rsa:2048 -keyout private.key -out cert.pem -days 365 

FOR THE PREVIOUS SSL:
 - Generated on 11/12/2024
 - For the pass key, I used a 6 number password I use for my phone...should be obvious