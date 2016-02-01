#-------------------------------------------------
#
# Project created by QtCreator 2015-10-29T00:27:50
#
#-------------------------------------------------

QT          -= core gui

CONFIG      += c++11
CONFIG      += sse2

QMAKE_CXXFLAGS += -fPIC

TARGET      = lsdSlamFrame
TEMPLATE    = lib

DEFINES += LSDSLAMFRAME_LIBRARY

SOURCES += \
            DataStructures/Frame.cpp                \
            DataStructures/FrameMemory.cpp          \
            DataStructures/FramePoseStruct.cpp      \
            DepthEstimation/DepthMap.cpp            \
            DepthEstimation/DepthMapPixelHypothesis.cpp

HEADERS += \
            DataStructures/Frame.h                  \
            DataStructures/FrameMemory.h            \
            DataStructures/FramePoseStruct.h        \
            DepthEstimation/DepthMap.h              \
            DepthEstimation/DepthMapPixelHypothesis.h

unix {
    # Boost
    LIBS    +=  -L/home/sergey/libs/boost_1_59_0/stage/lib      \
                -lboost_thread                                  \
                -lboost_system

    # OpenCV
    OPENCV_INCLUDE_PATH        = /home/sergey/libs/opencv-3.0.0/include
    OPENCV_INCLUDE_MODULE_PATH = /home/sergey/libs/opencv-3.0.0/release/modules

    OPENCV_LIBS_PATH           = /home/sergey/libs/opencv-3.0.0/release/lib

    message( " Unix - Version OpenCV - 3.00 - Release " )
    message( $$OPENCV_LIBS_PATH )

    LIBS    += -L$$OPENCV_LIBS_PATH
    LIBS    += -lopencv_objdetect   -lopencv_imgproc
    LIBS    += -lopencv_videoio     -lopencv_core
    LIBS    += -lopencv_imgcodecs   -lopencv_highgui
    LIBS    += -lopencv_features2d  -lopencv_calib3d

    # Sophus
    INCLUDEPATH += /home/sergey/MyProject/MySlamProject/Qt/
    INCLUDEPATH += /home/sergey/libs/Sophus

    INCLUDEPATH +=  /home/sergey/MyProject/MySlamProject/Qt/lsdSlamIO/
    LIBS        +=  -L/home/sergey/MyProject/MySlamProject/Qt/FullProject/build/lsdSlamIO   \
                    -llsdSlamIO

    INCLUDEPATH +=  /home/sergey/MyProject/MySlamProject/Qt/lsdSlamUtil/
    LIBS        +=  -L/home/sergey/MyProject/MySlamProject/Qt/FullProject/build/lsdSlamUtil \
                    -llsdSlamUtil

    INCLUDEPATH += /home/sergey/MyProject/MySlamProject/Qt/lsdSlamTracking/
#    LIBS        +=  -L/home/sergey/MyProject/MySlamProject/Qt/FullProject/build/lsdSlamTracking  \
#                    -llsdSlamTracking

    INCLUDEPATH +=  /home/sergey/MyProject/MySlamProject/Qt/lsdSlamGlobalMapping/
#    LIBS        +=  -L/home/sergey/MyProject/MySlamProject/Qt/FullProject/build/lsdSlamGlobalMapping \
#                    -llsdSlamGlobalMapping

    #INCLUDEPATH += /home/sergey/MyProject/MySlamProject/Qt/lsdSlamDepth/
    #LIBS        +=  -L/home/sergey/MyProject/MySlamProject/Qt/FullProject/build/lsdSlamDepth  \
    #                -llsdSlamDepth

    LIBS += -L/usr/local/cuda/lib64     -lcudart  -lcuda  \
#            -L/usr/local/qwt-6.1.2/lib  -lqwt

    CUDA_ARCH       = sm_32
    CUDA_SOURCES    = DataStructures/gpu_processor.cu

    cu.output       = ${QMAKE_FILE_BASE}.o
    cu.commands     = /usr/local/cuda/bin/nvcc -c --compiler-options '-fPIC' -arch=$$CUDA_ARCH ${QMAKE_FILE_NAME} -o ${QMAKE_FILE_OUT}

    cu.dependency_type = TYPE_C

    cu.input        = CUDA_SOURCES
    cu.CONFIG      += no_link
    cu.variable_out = OBJECTS

    QMAKE_EXTRA_COMPILERS += cu

    #target.path = /usr/lib
    target.path = /home/sergey/MyProject/MySlamProject/lsdSlamSharedLibs
    INSTALLS += target
}

