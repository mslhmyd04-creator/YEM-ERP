"""Actual request boundaries and competing writers; no production endpoint."""
import concurrent.futures
import json
import time
import unittest
import urllib.error
import urllib.parse
import urllib.request
from uuid import uuid4
from yem_erp_core.identity import mapping_key


def request(method, path, payload=None, *, authenticated=True):
    headers = {"Host": "yem-ci.localhost", "Accept": "application/json"}
    if authenticated:
        with open('/tmp/yem-ci-http.json') as handle:
            headers['Authorization'] = json.load(handle)['token']
    if method == 'GET' and payload:
        path += '?' + urllib.parse.urlencode(payload)
    body = None
    if method == 'POST':
        headers['Content-Type'] = 'application/json'
        body = json.dumps(payload or {}).encode()
    req = urllib.request.Request('http://127.0.0.1:8000' + path, body, headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as error:
        with error:
            return error.code, json.loads(error.read())


class HttpTests(unittest.TestCase):
    base = '/api/method/yem_erp_core.api.'

    def test_guest_denied(self):
        status, _ = request('GET', self.base + 'capabilities', {'company': 'YEM CI A'},
                            authenticated=False)
        self.assertIn(status, (401, 403))

    def test_company_scope(self):
        self.assertEqual(request('GET', self.base + 'capabilities', {'company': 'YEM CI A'})[0], 200)
        self.assertEqual(request('GET', self.base + 'capabilities', {'company': 'YEM CI B'})[0], 403)

    def test_native_resource_denies_other_company(self):
        key = mapping_key('YEM CI B', 'item', '6d5d6651-b0db-43a9-bdb6-6da68ca719d0')
        self.assertEqual(request('GET', '/api/resource/YEM%20Entity%20Mapping/' + key)[0], 403)

    def test_get_cannot_mutate(self):
        payload = dict(company='YEM CI A', entity_type='item', local_uuid=str(uuid4()),
                       target_name='YEM-CI-OTHER')
        status, _ = request('GET', self.base + 'bind_entity', payload)
        self.assertIn(status, (403, 405))
        payload.pop('target_name')
        self.assertEqual(request('GET', self.base + 'resolve_entity', payload)[0], 404)

    def test_racing_retries_resolve_one_mapping(self):
        payload = dict(company='YEM CI A', entity_type='item', local_uuid=str(uuid4()),
                       target_name='YEM-CI-SERVICE')
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            results = list(pool.map(lambda _: request('POST', self.base + 'bind_entity', payload), range(4)))
        successes = [body['message'] for status, body in results if status == 200]
        self.assertTrue(successes, results)
        self.assertTrue(all(status in (200, 409, 417, 500) for status, _ in results), results)
        for status, body in results:
            if status != 200:
                self.assertIn(body.get('exc_type'), {
                    'DuplicateEntryError', 'UniqueValidationError',
                    'QueryDeadlockError', 'QueryTimeoutError',
                }, body)
        retry_status, retry = request('POST', self.base + 'bind_entity', payload)
        self.assertEqual(retry_status, 200, retry)
        self.assertTrue(all(item == retry['message'] for item in successes))
        # Native Frappe resource lists must obey the same company restriction.
        status, rows = request('GET', '/api/resource/YEM%20Entity%20Mapping',
                               {'fields': json.dumps(['name', 'company'])})
        self.assertEqual(status, 200, rows)
        self.assertEqual(len(rows['data']), 1, rows)
        self.assertEqual(rows['data'][0]['company'], 'YEM CI A')


def main():
    for _ in range(30):
        try:
            request('GET', '/api/method/ping', authenticated=False)
            break
        except (OSError, urllib.error.URLError):
            time.sleep(1)
    else:
        raise RuntimeError('Local HTTP server did not start')
    unittest.main(module=__name__)


if __name__ == '__main__':
    main()
