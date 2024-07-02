#!/bin/bash

genhtml --branch-coverage --output genhtml "$(bazelisk info output_path)/_coverage/_coverage_report.dat"
