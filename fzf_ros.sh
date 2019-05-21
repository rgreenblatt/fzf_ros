#==============================================================================
# Constants
if [ -n "$FZF_ROSBAG_PLAY_COMMAND" ];
then
    echo "FZF_ROS: using existing rosbag play command."
else
    # Change this if you want your own rosbag play command
    export FZF_ROSBAG_PLAY_COMMAND="rosbag play --pause --clock --hz=200 "
fi

if [ -n "$FZF_ROSBAG_DIRS" ];
then
    echo "FZF_ROS: using existing rosbag directories."
else
    # Change this if you want your own rosbag play command
    export FZF_ROSBAG_DIRS="$HOME"
fi

# utility function used to write the command in the shell
writecmd() {
  perl -e '$TIOCSTI = 0x5412; $l = <STDIN>; $lc = $ARGV[0] eq "-run" ? "\n" : ""; $l =~ s/\s*$/$lc/; map { ioctl STDOUT, $TIOCSTI, $_; } split "", $l;' -- $1
}

#==============================================================================
# General ros tools

## roscd
fzf_roscd() {
    local package
    package=$(rospack list-names | fzf-tmux --query="$1" --select-1 --exit-0) &&
        roscd "$package"
}

## roslaunch
fzf_roslaunch() {
   find $ROS_DIR_PATH -type f -name "*.launch" | fzf-tmux --query="$1" --select-1 --exit-0 |\
        sed "s/^/roslaunch  /" | writecmd
}

## rosbag play
fzf_rosbag() {
   find $FZF_ROSBAG_DIRS -type f -name "*.bag" | fzf-tmux --query="$1" --select-1 --exit-0 |\
        sed "s/^/\$FZF_ROSBAG_PLAY_COMMAND/" | writecmd
}

## Run executables like rosrun (but not really rosrun)
fzf_rosrun() {
   find $ROS_DIR_PATH/devel/ $ROS_DIR_PATH/src/ -executable -type f | fzf-tmux --query="$1" --select-1 --exit-0 |\
        sed "s/^//" | writecmd
}

#==============================================================================
# Topic related tools
## Echo a topic
fzf_ros_topic_echo() {
    rostopic list > /dev/null &&
        rostopic list | fzf-tmux --query="$1" --select-1 --exit-0 |\
        sed "s/^/rostopic echo /" | writecmd
}

## Topic info
fzf_ros_topic_info() {
    local topic
    rostopic list > /dev/null &&
        topic=$(rostopic list | fzf-tmux --query="$1" --select-1 --exit-0) &&
        rosnode info "$topic"
}

#==============================================================================
# Node related tools
## Node info
fzf_ros_node_info() {
    local node
    rostopic list > /dev/null
        node=$(rosnode list | fzf-tmux --query="$1" --select-1 --exit-0) &&
        rosnode info "$node"
}

## Ping nodes
fzf_ros_node_ping() {
    local node
    rostopic list > /dev/null &&
        node=$(rosnode list | fzf-tmux --query="$1" --select-1 --exit-0) &&
        rosnode ping "$node"
}

## Kill nodes
fzf_ros_node_kill() {
    local node
    rostopic list > /dev/null &&
        node=$(rosnode list | fzf-tmux --query="$1" --select-1 --exit-0) &&
        rosnode kill "$node"
}

#==============================================================================
# Build tools
## Build a package - start immediately on match
fzf_catkin_build_immediate() {
    local package
    package=$(rospack list-names | fzf-tmux --query="$1" --select-1 --exit-0) &&
        catkin build -w $ROS_DIR_PATH -DCMAKE_EXPORT_COMPILE_COMMANDS=ON "$package"
}

## Build a package - prepare build command on command line for the user to
#  edit before starting a build
fzf_catkin_build_edit() {
    rospack list-names  | fzf-tmux --query="$1" --select-1 --exit-0 |\
        sed "s/^/catkin build -w \$ROS_DIR_PATH -DCMAKE_EXPORT_COMPILE_COMMANDS=ON  /" | writecmd
}

## Clean packages
fzf_ros_clean() {
    local package
    package=$(rospack list-names | fzf-tmux --query="$1" --select-1 --exit-0)
    local rclean_build_path=$ROS_DIR_PATH/build/$package
    local rclean_devel_path=$ROS_DIR_PATH/devel/lib/$package
    if [ -d $rclean_build_path ]; then
        echo "Removing $rclean_build_path" &&
        rm -rf $rclean_build_path > /dev/null
    else
        echo "$rclean_build_path does not exist"
    fi
    if [ -d $rclean_devel_path ]; then
        echo "Removing $rclean_devel_path" &&
        rm -rf $rclean_devel_path > /dev/null
    else
        echo "$rclean_devel_path does not exist"
    fi
}

