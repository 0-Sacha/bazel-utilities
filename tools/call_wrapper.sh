
REPORT_FILE=$1
shift
BINARY=$1
shift

touch $REPORT_FILE

"$BINARY" $@
