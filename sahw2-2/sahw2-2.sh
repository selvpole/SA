#!/bin/bash
Main() {
  # curlDownClass
  creatCosInfo
  login
}

login() {
  cat courseData/cos_id.txt | parseData > course.data
  dialog --title "Course Register System" \
  --msgbox "Welcome to the Course Register System" \
  15 60
  timeTable
}

buildTable() {
  for i in 1 2 3 4 5 6 7; do
    touch courseData/"$i".data
  done
  # frstLine='x              .Mon|              .Tue|              .Wed|              .Thu|              .Fri|'
  frstLine='x/|.Mon/|.Tue/|.Wed/|.Thu/|.Fri/|'
  sprtLine='./|===============/|===============/|===============/|===============/|===============/|'
  courseBox1="T/|1/|2/|3/|4/|5/|"
  courseBox2="./|;/|;/|;/|;/|;/|"
  # \n.;|/;|/;|/;|/;|/\n.;|/;|/;|/;|/;|/\n.;|/;|/;|/;|/;|/\n"
  null='x.'
  rm buildTable_tmp.txt
  touch buildTable_tmp.txt
  echo -e "$frstLine" >> buildTable_tmp.txt
  echo -e "$sprtLine" >> buildTable_tmp.txt
  for cls in A B C D E F G H I J K; do
    local frame=`echo $courseBox1 | sed -e "s/T/$cls/g"`

    for num in 1 2 3 4 5; do
      local cosNum=`cat courseData/"$num".data | grep $cls | cut -d '-' -f2`
      if [ ! -n "$cosNum" ]; then
        cosNum=$null
      fi
      tmp=`echo $frame | sed -e "s/$num/$cosNum/g"`
      frame=$tmp
    done

    echo $frame >> buildTable_tmp.txt
    for i in 1 2 3; do
      echo $courseBox2 | sed -e "s/;/./g" >> buildTable_tmp.txt
    done
    echo $sprtLine >> buildTable_tmp.txt
  done
  column -s "/" -t buildTable_tmp.txt > buildTable.txt
}

timeTable() {
  buildTable
  # build dialog
  dialog --backtitle "class table" --ok-label "Add Class" \
  --extra-button --extra-label "options" \
  --help-button --help-label "exit" --textbox "buildTable.txt" \
  100 100
  local result=$?
  if [ $result = 0 ] ; then
    addClass
  elif [ $result = 3 ] ; then
    login
  fi
}

addClass() {
  rm -f courseData/*.data
  rm sel_cosID_tmp*.data

  cp sel_cosID.data sel_cosID_tmp.data

  cat course.data | BuildList | xargs dialog --title "Course Table" \
  --buildlist "Choose a course: " 100 200 50 2> sel_cosID_tmp.data
  # OK/Cancel
  rm sel_cosID.data
  stat=$?
  if [ $stat -eq 0 ]; then
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

    touch sel_cosID.data
    cat sel_cosID_tmp2.data | detection
  fi
  cat sel_cosID.data | makeComplete
  # dialog --title "Loading" --infobox "Please wait..." 15 60; sleep 1
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
      # local col=`echo $tm | detection`
      # if [ $col = "no" ]; then
      stat='on'
      # echo "$tm-$nm" | complete
      # else
      #   stat='off'
      #   colError
      # fi
    else
      stat='off'
    fi
    echo "$id/$tm \"$tm $rm - $nm\" $stat"
  done
  # cat courseData/complete_tmp.data > courseData/complete.data

}

detection() {
  local collision='n'
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
    grep $checkID courseData/colID.data
    if [ $? -ne 0 ]; then
      echo "$checkID" >> courseData/colID.data
      echo "$checkTm, $checkNm\n" >> courseData/collision.data
    fi
  done
}

makeComplete() {
  for i in 1 2 3 4 5 6 7; do
    touch courseData/$i.data
  done
  # ex. 0411 1G
  while read line; do
    id=`echo $line | cut -d ' ' -f1`
    rm=`cat course.data | grep $id | cut -d ';' -f3`
    nm=`cat course.data | grep $id | cut -d ';' -f4`
    dy=`echo $line | awk -F ' ' '{split($2, arr, "")} END{print arr[1]}'`
    tm=`echo $line | awk -F ' ' '{split($2, arr, "")} END{print arr[2]}'`
    # classify the course
    echo "$tm-$nm-$rm" >> "courseData/$dy.data"
    echo "$dy$tm-$nm-$rm" >> courseData/complete.data
  done

  for i in 1 2 3 4 5 6 7; do
    sort "courseData/$i.data"
  done
}

# makeComplete() {
#   read id
#   tm=`grep $id course.data | cut -d ';' -f2`
#
#   touch courseData/1mon.data
#   touch courseData/2tue.data
#   touch courseData/3wed.data
#   touch courseData/4thu.data
#   touch courseData/5fri.data
#   touch courseData/6sat.data
#   touch courseData/complete.data
#   echo "$tm,$nm,$rm" | awk -F',' '{split($1,arr,"")}
#   END{
#     for(i in arr){
#       if(arr[i] ~ /[0-9]/){
#         day=arr[i]
#       }
#     else if(arr[i] ~ /[A-Z]/){
#         slot=arr[i]
#         if(day == '1')
#             print slot, $2 >> "courseData/1mon.data"
#         else if(day == '2')
#             print slot, $2 >> "courseData/2tue.data"
#         else if(day == '3')
#             print slot, $2 >> "courseData/3wed.data"
#         else if(day == '4')
#             print slot, $2 >> "courseData/4thu.data"
#         else if(day == '5')
#             print slot, $2 >> "courseData/5fri.data"
#         else if(day == '6')
#             print slot, $2 >> "courseData/6sat.data"
#
#         print day slot, $2, $3 >> "courseData/complete.data"
#       }
#     }
#   }'
# }

# curlDownClass(){
#   echo `curl 'https://timetable.nctu.edu.tw/?r=main/get_cos_list' --data \
#   'm_acy=107&m_sem=1&m_degree=3&m_dep_id=17&m_group=**&m_grade=**&m_class=**&m_option=**&m_crsname=**&m_teaname=**&m_cos_id=**&m_cos_code=**&m_crstime=**&m_crsoutline=**&m_costype=**'`\
#   > courseData/courseFile.json
# }

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
      # | grep -Eo '[1-7][A-NXY]+' | paste -sd ',' -
      echo "$id;$time;$room;$name"
      sed -i '1d' courseData/cos_ename.txt
      sed -i '1d' courseData/cos_time.txt
      sed -i '1d' courseData/cos_room.txt
    fi
  done
  # rm cos_id.txt cos_time.txt cos_room.txt cos_ename.txt \
  # courseFile.json
}

Main
