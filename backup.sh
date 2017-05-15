
MYNAME="$0"
MYDIR=`dirname $0`

. $MYDIR/postgre.env

#
# directory:
#	BACKUP_BASE_DIR/latest	 .... latest backup
#	BACKUP_BASE_DIR/latest-01 ... backup of one before
#	BACKUP_BASE_DIR/latest-02 ... backup of two before
#		:
#	BACKUP_BASE_DIR/latest-<$N_PREV> ... most old backup
#

N_PREV=3

PREV_FMT="latest-%02d";

get_backup_dirname() # prev_num
{
	prev_num="$1"
	dname="`printf $PREV_FMT $prev_num;`";
	echo "$BACKUP_BASE_DIR/$dname";
}

LANG=C
export LANG

echo "LOG: START : `date`";

prev_from=`expr $N_PREV - 1`;
prev_to=$N_PREV

while [ "$prev_from" -ge 0 ]
do
	PREV_FROM_DIR=`get_backup_dirname $prev_from`;
	PREV_TO_DIR=`get_backup_dirname $prev_to`;

	if [ -d "$PREV_TO_DIR" ]; then
		echo "LOG: remove $PREV_TO_DIR";
		rm -rf "$PREV_TO_DIR";
	fi
	if [ -d "$PREV_FROM_DIR" ]; then
		echo "LOG: move $PREV_FROM_DIR -> $PREV_TO_DIR";
		mv "$PREV_FROM_DIR" "$PREV_TO_DIR";
	fi
	prev_from=`expr $prev_from - 1`;
	prev_to=`expr $prev_to - 1`;
done

BACKUP_DIR=`get_backup_dirname 0`;

echo "LOG: execute backup into $BACKUP_DIR"
pg_basebackup -x -D $BACKUP_DIR

echo "LOG: END : `date`";

