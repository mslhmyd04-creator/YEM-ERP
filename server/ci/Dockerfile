FROM frappe/erpnext:v16.50.0
USER root
COPY --chown=frappe:frappe server/yem_erp_core /home/frappe/frappe-bench/apps/yem_erp_core
COPY --chown=frappe:frappe server/ci/run.sh /home/frappe/run-yem-tests.sh
USER frappe
RUN /home/frappe/frappe-bench/env/bin/pip install --no-cache-dir -e /home/frappe/frappe-bench/apps/yem_erp_core
WORKDIR /home/frappe/frappe-bench
ENTRYPOINT ["bash", "/home/frappe/run-yem-tests.sh"]
