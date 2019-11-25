# -*- coding: utf-8 -*-
import hy
import sys
import os

sys.path.append(os.getcwd())

from time import time
from datetime import datetime

from lib import ProtocolBot
from lib.cron.CronJob import CronJob

def test_the_basics():
  assert "foo" != "bar"

def test_create_basic_job():
  job_run = time() + 30
  job = CronJob(job_run, lambda x: x + x, [5], {}, disp_name="foobar", plugin="barfoo")
  assert job.id != None
  assert job.next_run == job_run
  assert job.context == {}
  assert job.disp_name == "foobar"
  assert job.plugin == "barfoo"
  assert str(job) == "foobar"
  assert not job.recurring

def test_create_recurring_job():
  job_run = "PT3H4M"
  exp_time = int(time())
  job = CronJob(job_run, lambda x: x + x, [5], {}, disp_name="foobar", plugin="barfoo")
  assert job.id != None
  assert int(job.next_run) in range(exp_time, exp_time + 2)
  assert job.context == {}
  assert job.disp_name == "foobar"
  assert job.plugin == "barfoo"
  assert str(job) == "foobar"
  assert job.recurring

def test_calc_next_run_recurring_job():
  job_run = "PT3H4M"
  exp_time = int(time())
  job = CronJob(job_run, lambda x: x + x, [5], {})
  assert int(job.next_run) in range(exp_time, exp_time + 2)
  exp_time += 11040
  job.calc_next_run()
  assert int(job.next_run) in range(exp_time, exp_time + 2)
  exp_time += 11040
  job.calc_next_run()
  assert int(job.next_run) in range(exp_time, exp_time + 2)

def test_calc_with_start_date():
  job_run = "P1DT2S"
  start = int(time()) + 36000000
  job = CronJob(job_run, lambda x: x+x, [5], {}, start=datetime.fromtimestamp(start).isoformat())
  assert int(job.next_run) == start
  job.calc_next_run()
  assert int(job.next_run) == start + 86402
