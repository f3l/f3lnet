#!/usr/bin/python2
# -*- coding: utf-8 -*-

import os
from flask import Flask, render_template
from flask.ext.bootstrap import Bootstrap
from flask import url_for
from flask import session
from flask import redirect
from flask import request
from flask import flash
from flask import make_response
import hosts
import passwd
try:
	import simplejson as json
except ImportError:
	import json

app = Flask(__name__)
Bootstrap(app)
try:
	app.secret_key = open('secret.key').read()
except:
	app.secret_key = os.urandom(24)
	open('secret.key', 'w').write(app.secret_key)
config = json.load(open('config.json'))
hostlist = hosts.HostList(config)

@app.route('/')
def index():
	return render_template('base.html')

@app.route('/install')
def install():
	return render_template('install.html')

@app.route('/f3lnet.sh')
def f3lnet_sh():
	resp = make_response(render_template('f3lnet.sh',
		tld = config['tld'],
		essid = config['essid'],
		bssid = config['bssid'],
		channel = config['channel'],
		subnet = config['subnet'].split('/')[1],
		host_url = "%shosts.txt" % request.url_root
	))
	resp.headers['Content-Type'] = 'text/plain'
	return resp

@app.route('/hosts', methods=['GET', 'POST'])
def hosts():
	if request.method == 'GET':
		return render_template('hosts.html', hosts=hostlist.all(), next_ip=hostlist.next_ip())
	else:
		if 'username' in session:
			if 'delete' in request.form:
				host = request.form.get('delete')
				hostlist.delete(host)
				flash('Host "%s" deleted.' % host, 'success')
			elif request.form.get('add', None):
				host = request.form.get('add')
				hostlist.add(host)
				flash('Host "%s" added.' % host, 'success')
		return redirect(url_for('hosts'))

@app.route('/hosts.txt')
def hosts_txt():
	resp = make_response(render_template('hosts.txt', hosts=hostlist.all()))
	resp.headers['Content-Type'] = 'text/plain'
	return resp

@app.route('/debug')
def debug():
	return render_template('debug.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
	if request.method == 'POST':
		username = request.form.get('user')
		password = request.form.get('pass')
		endpoint = request.form.get('endpoint')
		auth = False
		for line in open(config['passwd']).readlines():
			if line.startswith("%s:" % username.encode('UTF-8')):
				pw_hash = line.split(':')[1]
				auth = passwd.test(password, pw_hash)
				break
		if auth:
			session['username'] = username
			flash('Login successfull.', 'success')
		else:
			flash('Login failed.', 'error')
		return redirect(url_for(endpoint))
	return redirect(url_for('index'))

@app.route('/logout')
def logout():
	session.pop('username', None)
	flash('Logout successfull.', 'success')
	return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True)
