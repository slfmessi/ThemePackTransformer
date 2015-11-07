#!/bin/bash
#
# A script to transfer Windows themepack file to Gnome slideshowWallpapers
# 
# Remember: you need to have cabextract installed
# for Ubuntu: apt-get install cabextract

readonly file_type="jpg|png"
readonly properties_folder=$HOME/.local/share/gnome-background-properties
readonly content_folder=$HOME/.local/share/backgrounds # store all theme content

theme_name=
theme_folder=
slideshow_xml=
# set default time interval
static_time=595
transition_time=5

set_file_path() {
  theme_file=$1
  theme_fullname=${theme_file##*/}
  theme_name=${theme_fullname%.*}
  theme_folder=$content_folder/$theme_name
  slideshow_xml=$content_folder/$theme_name/$theme_name.xml
  
  mkdir -p $content_folder/$theme_name
  cabextract -d /tmp/$theme_name/ $1 > /dev/null && mv /tmp/$theme_name/DesktopBackground/* $content_folder/$theme_name/
}

# generate slideshow xml
# param : 
#    $1 : date string
generate_slideshow_xml() {
  date_str=$1
  year=${date_str:0:4}
  month=${date_str:5:2}
  day=${date_str:8:2}
  
  echo "<background>"
  echo "  <starttime>"
  echo "    <year>$year</year>"
  echo "    <month>$month</month>"
  echo "    <day>$day</day>"
  echo "    <hour>00</hour>"
  echo "    <minute>00</minute>"
  echo "    <second>00</second>"
  echo "  </starttime>"
  echo "<!-- This animation starts at midnight of $Yer/$Mnth/$Day.  -->"

  # find all image files
  image_list=$( find -L $content_folder/$theme_name \
                     -regextype posix-extended \
                     -iregex ".*\.($file_type)" \
                     | sort )

  # count files and calculate interval
  static_head="  <static>\n    <duration>$static_time</duration>\n    <file>"
  static_tail="</file>\n  </static>"
  from_head="  <transition>\n    <duration>$transition_time</duration>\n    <from>"
  from_tail="</from>"
  to_head="    <to>"
  to_tail="</to>\n  </transition>"

  image_count=$( echo "$image_list" | wc -l)
  first_image=$( echo "$image_list" | head -n 1)
  for (( i = 0; i < $image_count; i++ )); do
    #statements
    static_image=$( echo "$image_list" | sed -n `expr $i + 1`p )
    to_image=$( echo "$image_list" | sed -n `expr $i + 2`p )
    if [[ $i -eq `expr $image_count - 1` ]]; then
      to_image=$first_image
    fi
    echo "  <static>"
    echo "    <duration>$static_time</duration>"
    echo "    <file>$static_image</file>"
    echo "  </static>"
    echo "  <transition>"
    echo "    <duration>$transition_time</duration>"
    echo "    <from>$static_image</from>"
    echo "    <to>$to_image</to>"
    echo "  </transition>"
  done
  echo "</background>"
}

generate_properties_xml() {
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  echo "<!DOCTYPE wallpapers SYSTEM \"gnome-wp-list.dtd\">"
  echo "<wallpapers>"
  echo "  <wallpaper>"
  echo "    <name>$theme_name</name>"
  echo "    <filename>$slideshow_xml</filename>"
  echo "    <options>zoom</options>"
  echo "    <shade_type>solid</shade_type>"
  echo "  </wallpaper>"
  echo "</wallpapers>"
}


# main

mkdir -p $properties_folder
set_file_path $1
shift

# get options
while getopts :t: optname; do
  #statements
  case $optname in
    "t")
      static_time=`expr $OPTARG - $transition_time`;;
    "?")
      echo "wrong parameter";;
  esac
done

date=`date +%Y-%m-%d`
generate_slideshow_xml $date > $slideshow_xml
generate_properties_xml > $properties_folder/$theme_name-wallpapers.xml