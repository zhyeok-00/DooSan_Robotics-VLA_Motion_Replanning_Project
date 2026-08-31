cmake_minimum_required(VERSION 3.8)
project(m0609_rg2_bringup)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)

# scripts는 launch에서 import 하므로 share에도 깐다 (calib_npy_to_tf).
# 장비별 캘리브레이션 npy는 저장소 밖에 두고 launch 인자/환경변수로 지정한다.
install(
  DIRECTORY urdf launch rviz meshes scripts config
  DESTINATION share/${PROJECT_NAME}
)

install(
  PROGRAMS
    scripts/gripper_joint_state_publisher.py
    scripts/gripper_virtual_node.py
    scripts/calib_npy_to_tf.py
    scripts/depth_downsample_node.py
  DESTINATION lib/${PROJECT_NAME}
)

ament_package()
