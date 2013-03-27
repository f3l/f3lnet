#!/usr/bin/python2

import os
import ipaddr

class HostList:
	def __init__(self, config):
		self.config = config
		self.network = ipaddr.IPNetwork(config['subnet'])
	
	@property
	def ips(self):
		# make a copy - access with result.next()
		return self.network.iterhosts() 

	@property
	def hosts(self):
		if os.path.isfile('hosts.txt'):
			content = open('hosts.txt').read()
			hosts = content.split("\n")
		else:
			hosts = []
		if '' in hosts:
			hosts.remove('')
		return hosts

	def all(self):
		ips = self.ips
		for host in self.hosts:
			yield ("%s.%s" % (host, self.config['tld']), ips.next())
	
	def next_ip(self):
		ips = self.ips
		for host in self.hosts:
			ips.next()
		return ips.next()
	
	def delete(self, host):
		host = host.replace(".%s" % self.config['tld'], '')
		hosts = self.hosts
		hosts.remove(host)
		content = "\n".join(hosts)
		open('hosts.txt', 'w').write(content)

	def add(self, host):
		host = host.replace(".%s" % self.config['tld'], '')
		hosts = self.hosts
		hosts.append(host)
		content = "\n".join(hosts)
		open('hosts.txt', 'w').write(content)
