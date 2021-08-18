amazon-linux-extras-install-epel:
  cmd.run:
    - name: amazon-linux-extras install epel -y
    - unless:
      - /bin/amazon-linux-extras list | grep epel | grep -c enabled

clamav:
  pkg.installed

clamav-update:
  pkg.installed

clamd:
  pkg.installed

freshclam-log:
  file.managed:
    - name: /var/log/freshclam.log
    - mode: 660
    - require:
      - pkg: clamav-update


freshclam:
  cmd.run:
    - name: /usr/bin/freshclam --log=/var/log/freshclam.log
    - require:
      - pkg: clamav-update
      - file: freshclam-log
      - file: /etc/clamd.d/freshclam.conf

clamd@service:
  service.running:
    - require:
      - cmd: freshclam
      - pkg: clamd
      - file: /etc/clamd.d/service.conf
    - enable: True
    - init_delay: 30

clamonacc.service:
  service.running:
    - require:
      - cmd: freshclam
      - pkg: clamav
      - file: /etc/clamd.d/scan.conf
      - service: clamd@service

/etc/clamd.d/service.conf:
  file.managed:
    - source:
      - salt://clamav/files/service.conf
    - template: jinja
    - replace: True
    
/etc/clamd.d/scan.conf:
  file.managed:
    - source:
      - salt://clamav/files/scan.conf
    - template: jinja
    - replace: True

/etc/clamd.d/freshclam.conf:
  file.managed:
    - source:
      - salt://clamav/files/freshclam.conf
      - replace: True

freshclam-cron:
  cron.present:
    - name: /usr/bin/freshclam --log=/var/log/freshclam.log
    - minute: '*/15'
    - identifier: freshclam
    - require:
      - pkg: clamav-update
      - file: freshclam-log
