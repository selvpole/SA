#!/bin/bash
Main() {
  mkdir courseData
  # curlDownClass
  creatData
  login
}

login() {
  dialog --title "Course Register System" \
  --msgbox "Welcome to the Course Register System" \
  15 60
  timeTable
}

timeTable() {
  if [ ! -f courseData/1.data ]; then
    for i in `seq 1 7`; do
      touch courseData/"$i".data
      for j in M N A B C D X E F G H I J K L; do
        echo "$j;x;x" >> courseData/$i.data
      done
    done
  fi

  if [ ! -f mod ]; then
    buildTable 2 0
  else
    case `cat mod` in
      op1) buildTable 2 0;;
      op2) buildTable 3 0;;
      op3) buildTable 2 1;;
    esac
  fi
  # build dialog
  dialog --backtitle "class table" --ok-label "Add Class" \
  --extra-button --extra-label "options" \
  --help-button --help-label "exit" --textbox "buildTable.txt" \
  100 100
  local result=$?
  if [ $result = 0 ] ; then
    addClass
  elif [ $result = 3 ] ; then
    changeMod
  fi
}

changeMod() {
  dialog --backtitle "Option" --menu "Option" 40 60 3 \
  op1 "Origin" \
  op2 "Show Classroom" \
  op3 "Hide Extra Column" 2> mod

  timeTable
}

buildTable() {
  local field=$1 # 2:course name; 3:class room
  local hide=$2 # 0:hide 1:show
  local filter="^[Z]"
  local hid1="7_col.data"
  local hid2="6_col.data"
  local h_line='.Mon .Tue .Wed .Thu .Fri .Sat .Sun '
  # hide
  if [ $hide -eq 0 ]; then
    filter="^[MNXYL]"
    hid1=""
    hid2=""
  fi

  # waiting
  dialog --infobox "building the table..." 3 25

  # head column
  echo 'x ' | form 1 1 > h_col.data
  for i in M N A B C D X E F G H I J K L; do
    echo $i | grep -vE $filter | form 4 1
  done >> h_col.data

  # i column
  for i in `seq 1 7`; do
    echo $h_line | cut -d ' ' -f $i | sed "s/$/ /g" | form 1 12 > "$i"_col.data
    cat courseData/$i.data | grep -vE $filter | cut -d ';' -f $field | \
    form 4 12 >> "$i"_col.data
  done
  paste -d '' h_col.data $hid1 1_col.data 2_col.data 3_col.data 4_col.data 5_col.data $hid2 | \
  column -t > buildTable.txt

  rm -f *_col.data
}


form() {
  local height=$1
  local width=$2
  while read line; do
    line=`echo $line | tr ' ' '_'`
    for i in `seq 1 $height`; do
      echo "$line." | cut -c -$width | sed 's/$/ |/g'
      line=`echo $line | cut -c $width- | cut -c 2-`
    done
    printf "%0.s=" $(seq 1 $width)
    printf " |\n"
  done
}

addClass() {
  rm sel_cosID_tmp*.data
  cp sel_cosID.data sel_cosID_tmp.data

  cat course.data | BuildList | xargs dialog --title "Course Table" \
  --buildlist "Choose a course: " 100 200 50 2> sel_cosID_tmp.data
  stat=$?
  # OK/Cancel
  if [ $stat -eq 0 ]; then
    # clean sel_cosID.data
    echo "" > sel_cosID.data
    rm -f courseData/*.data
    cosID=`cat sel_cosID_tmp.data | sed -e 's/ /\n/g'`
    for line in $cosID; do
      echo $line | awk -F'/' '{split($2,arr,"")}
      END{
        for(i in arr){
          if(arr[i] ~ /[0-9]/)
            tm=arr[i]
          else if(arr[i] ~ /[A-Z]/){
            slot=arr[i]
            print $1, tm slot
          }
        }
      }' >> sel_cosID_tmp2.data
    done
    cat sel_cosID_tmp2.data | detection
  fi
  cat sel_cosID.data | makeComplete
  timeTable
}

BuildList() {
  # import course.data
  while read cos_list; do
    local id=`echo $cos_list | cut -d";" -f1`
    local tm=`echo $cos_list | cut -d";" -f2`
    local rm=`echo $cos_list | cut -d";" -f3`
    local nm=`echo $cos_list | cut -d";" -f4`
    cat sel_cosID.data | grep -q $id
    sel=$?  # selected?
    if [ $sel -eq 0 ]; then
      stat='on'
    else
      stat='off'
    fi
    echo "$id/$tm \"$tm $rm - $nm\" $stat"
  done
}

detection() {
  local collision='n'
  # > sel_cos_tmp2.data
  # ex. 0411 1G
  while read line; do
    checkTime=`echo $line | cut -d ' ' -f2`
    cosID=`echo $line | cut -d ' ' -f1`
    cosTime=`grep $cosID course.data | cut -d ';' -f2`
    cosName=`grep $cosID course.data | cut -d ';' -f4`
    grep -q $checkTime sel_cosID.data
    if [ $? -ne 0 ]; then
      echo $line >> sel_cosID.data
    else  # collision
      collision='y'
      echo "$cosID;$cosTime;$cosName" | makeColData
    fi
  done
  if [ $collision = 'y' ]; then
    tmp=`cat courseData/collision.data`
    dialog --msgbox "Collision:\n$tmp" 10 40
    addClass
  fi
}

makeColData() {
  touch courseData/colID.data
  while read data; do
    checkID=`echo $data | cut -d ';' -f1`
    checkTm=`echo $data | cut -d ';' -f2`
    checkNm=`echo $data | cut -d ';' -f3`
    grep -q $checkID courseData/colID.data
    if [ $? -ne 0 ]; then
      echo "$checkID" >> courseData/colID.data
      echo "$checkTm, $checkNm\n" >> courseData/collision.data
    fi
  done
}

makeComplete() {
  # ex. 0411 1G
  touch complete.data
  while read line; do
    id=`echo $line | cut -d ' ' -f1`
    rm=`cat course.data | grep $id | cut -d ';' -f3`
    nm=`cat course.data | grep $id | cut -d ';' -f4`
    dy=`echo $line | awk -F ' ' '{split($2, arr, "")} END{print arr[1]}'`
    tm=`echo $line | awk -F ' ' '{split($2, arr, "")} END{print arr[2]}'`
    # classify the course
    echo "$dy$tm;$nm;$rm" >> complete.data
  done
  rm courseData/*.data
  # make day.data
  for i in 1 2 3 4 5 6 7; do
    touch courseData/$i.data
    for j in M N A B C D X E F G H I J K L; do
      local cos=`grep -E ^[$i][$j] complete.data`
      if [ ! -n "$cos" ]; then
        echo "$j;x;x" >> courseData/$i.data
      else
        echo $cos | sed -e "s/$i$j/$j/g" >> courseData/$i.data
      fi
    done
  done
  rm complete.data
}

creatData() {
  if [ ! -f course.data ]; then
    if [ ! -f courseData/courseFile.json ]; then
      curlDownClass
    fi
    creatCosInfo
    cat courseData/cos_id.txt | parseData > course.data
  fi
  rm courseData/*.txt
}

curlDownClass(){
  echo `curl 'https://timetable.nctu.edu.tw/?r=main/get_cos_list' --data \
  'm_acy=107&m_sem=1&m_degree=3&m_dep_id=17&m_group=**&m_grade=**&m_class=**&m_option=**&m_crsname=**&m_teaname=**&m_cos_id=**&m_cos_code=**&m_crstime=**&m_crsoutline=**&m_costype=**'`\
  > courseData/courseFile.json
}

creatCosInfo() {
  # list class ID
  grep -o '"cos_id":"[^"]*"' courseData/courseFile.json | grep -o '"[^"]*"$' | tr -d '"' > courseData/cos_id.txt
  # list course
  grep -o '"cos_ename":"[^"]*"' courseData/courseFile.json | grep -o '"[^"]*"$' | tr -d '"' > courseData/cos_ename.txt
  # list time
  grep -o '"cos_time":"[^"]*"' courseData/courseFile.json | grep -o '"[^"]*"$' | tr -d '"' | awk -F'-' '{print $1}' > courseData/cos_time.txt
  # list room
  grep -o '"cos_time":"[^"]*"' courseData/courseFile.json | grep -o '"[^"]*"$' | tr -d '"' | awk -F'-' '{print $2}' > courseData/cos_room.txt
}

parseData() {
  local id
  while read id ; do
    grep -q $id course.data
    exist=$?
    if [ $exist -ne 0 ]; then
      read room < courseData/cos_room.txt
      read name < courseData/cos_ename.txt
      read t < courseData/cos_time.txt
      local time="`echo $t | tr -d '-'`"
      echo "$id;$time;$room;$name"
      sed -i '1d' courseData/cos_ename.txt
      sed -i '1d' courseData/cos_time.txt
      sed -i '1d' courseData/cos_room.txt
    fi
  done
}

Main
