from mitmproxy import http
import os
from requests_toolbelt.multipart.decoder import MultipartDecoder
from requests_toolbelt.multipart.encoder import MultipartEncoder
import re
import logging


def read_image(path='target.png'):
    if not os.path.exists(path):
        return None
    with open(path, 'rb') as f:
        return f.read()


class Heytea:
    def request(self, flow: http.HTTPFlow):
        host = flow.request.pretty_host
        path = flow.request.path
        if host == 'go.heytea.com' and '/api/service-cps/user/diy' in path and flow.request.multipart_form[b'file']:
            form = MultipartDecoder(flow.request.content, flow.request.headers['Content-Type'])
            parts = {}
            for part in form.parts:
                if 'filename' in part.headers.get(b'Content-Disposition', b'').decode():
                    pattern = r'name="(.*?)".*?filename="(.*?)"'
                    match = re.search(pattern, part.headers[b'Content-Disposition'].decode())
                    if not match:
                        logging.error('Error parsing Content-Disposition header')
                        return
                    name = match.group(1)
                    filename = match.group(2)
                    content_type = part.headers[b'Content-Type'].decode()
                    parts[name] = (filename, read_image(), content_type)
                else:
                    pattern = r'name="(.*?)"'
                    match = re.search(pattern, part.headers[b'Content-Disposition'].decode())
                    if not match:
                        logging.error('Error parsing Content-Disposition header')
                        return
                    name = match.group(1)
                    parts[name] = part.content.decode()
            encoder = MultipartEncoder(parts)
            flow.request.set_content(encoder.to_string())
            flow.request.headers['Content-Type'] = encoder.content_type


addons = [Heytea()]
