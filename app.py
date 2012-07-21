# -*- coding: utf-8 -*-
#
# Copyright (c) 2012, Chi-En Wu
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the organization nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from urllib import urlencode
from urllib2 import urlopen

from flask import Flask, render_template, json, jsonify

_BASE_URL = 'http://conceptnet5.media.mit.edu/data/5.1'

app = Flask(__name__)
app.debug = True


def _request(url, **kwargs):
    response = urlopen(_BASE_URL + url + '?' + urlencode(kwargs))
    result = response.read()
    return json.loads(result)


def _construct(lang, term, info):
    rel_map = {}
    for edge in info['edges']:
        rel = edge['rel']
        if rel not in rel_map:
            rel_map[rel] = []

        node = {
            'name': edge['endLemmas'],
            'lang': edge['end'].split('/')[2],
            'type': 'target',
            'score': edge['score']
        }
        rel_map[rel].append(node)

    rel_list = [{
        'name': rel.startswith('/c/') and rel.split('/')[3] or rel[3:],
        'lang': rel.startswith('/c/') and rel.split('/')[2] or None,
        'type': 'rel',
        'children': nodes
    } for rel, nodes in rel_map.iteritems()]

    result = {
        'name': term,
        'lang': lang,
        'type': 'root',
        'children': rel_list,
        'maxScore': info['maxScore']
    }
    return jsonify(result)


@app.route('/view/<lang>/<term>')
def view(lang, term):
    return render_template('index.html', term=term, lang=lang)


@app.route('/c/<lang>/<term>')
def lookup(lang, term):
    url = u'/c/{0}/{1}'.format(lang, unicode(term)).encode('utf-8')
    result = _request('/search', start=url, limit=20)
    return _construct(lang, term, result)


if __name__ == '__main__':
    app.run()
