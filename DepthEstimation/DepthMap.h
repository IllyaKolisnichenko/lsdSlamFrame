/**
* This file is part of LSD-SLAM.
*
* Copyright 2013 Jakob Engel <engelj at in dot tum dot de> (Technical University of Munich)
* For more information see <http://vision.in.tum.de/lsdslam> 
*
* LSD-SLAM is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* LSD-SLAM is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with LSD-SLAM. If not, see <http://www.gnu.org/licenses/>.
*/

#pragma once

#include <stdio.h>
#include <fstream>
#include <iostream>
#include <memory>
#include <limits>

#include "opencv2/opencv.hpp"

#include "sophus/se3.hpp"

#include "IndexThreadReduce.h"

namespace lsd_slam
{

class DepthMapPixelHypothesis;
class Frame;
class KeyFrameGraph;

/**
 * Keeps a detailed depth map (consisting of DepthMapPixelHypothesis) and does
 * stereo comparisons and regularization to update it.
 */
class DepthMap
{
public:
	EIGEN_MAKE_ALIGNED_OPERATOR_NEW

    //******************** Конструктор / Диструктор ****************************
    /**
     * @brief DepthMap
     *
     * Constructor
     *
     * @param w
     * @param h
     * @param K
     */
    DepthMap(   int w, int h, const Eigen::Matrix3f& K  );

    /**
     * @brief DepthMap
     *
     * Lock the implementation of the "copy" operator.
     */
    DepthMap(const DepthMap&)               = delete;
    DepthMap& operator=(const DepthMap&)    = delete;

    /**
     * Destructor
     */
	~DepthMap();

    /**
     * @brief reset
     *
     * Resets everything. Marks all hyphothesises as invalid.
     */
    void reset();
	
    /**
     * @brief createKeyFrame
     *
     * Does propagation and whole-filling-regularization (no observation, for that need to call updateKeyframe()!)
     *
     * @param new_keyframe
     */
    void createKeyFrame( Frame* new_keyframe);

    /**
     * @brief updateKeyframe
     *
     * Does obervation and regularization only.
     *
     * @param referenceFrames
     */
    void updateKeyframe( std::deque< std::shared_ptr<Frame> > referenceFrames );
	
    /**
     * @brief finalizeKeyFrame
     *
     * Does one fill holes iteration.
     */
	void finalizeKeyFrame();

	void invalidate();

    /**
     * @brief isValid
     * @return Returns TRUE if pointer to the frame is NOT null.
     */
    inline bool isValid() {return m_poActiveKeyFrame != 0;};

	int debugPlotDepthMap();

	// ONLY for debugging, their memory is managed (created & deleted) by this object.

    /** @name Debugging
     * ONLY for debugging, their memory is managed (created & deleted) by this object.
     */
    ///@{
    cv::Mat debugImageHypothesisHandling;
	cv::Mat debugImageHypothesisPropagation;
	cv::Mat debugImageStereoLines;
	cv::Mat debugImageDepth;
    ///@}

    void initializeFromGTDepth  (Frame* new_frame);

    /**
     * @brief initializeRandomly
     *
     * Initialization of depth map.
     *
     * @param new_frame
     */
    void initializeRandomly     (Frame* new_frame);

	void setFromExistingKF(Frame* kf);

	void addTimingSample();

    float msUpdate;
    float msCreate;
    float msFinalize;

    float msObserve;
    float msRegularize;
    float msPropagate;
    float msFillHoles;
    float msSetDepth;

    int nUpdate;
    int nCreate;
    int nFinalize;

    int nObserve;
    int nRegularize;
    int nPropagate;
    int nFillHoles;
    int nSetDepth;

	struct timeval lastHzUpdate;

    float nAvgUpdate;
    float nAvgCreate;
    float nAvgFinalize;

    float nAvgObserve;
    float nAvgRegularize;
    float nAvgPropagate;
    float nAvgFillHoles;
    float nAvgSetDepth;

    /// Pointer to global keyframe graph
	IndexThreadReduce threadReducer;

private:
	// camera matrix etc.
	Eigen::Matrix3f K, KInv;
    float fx;
    float fy;
    float cx;
    float cy;
    float fxi;
    float fyi;
    float cxi;
    float cyi;

    int width;
    int height;

	// ============= parameter copies for convenience ===========================
	// these are just copies of the pointers given to this function, for convenience.
	// these are NOT managed by this object!
    // Pointer to the current Key Frame
    Frame* m_poActiveKeyFrame;

    // Pointer to the mutex of current Key Frame
	boost::shared_lock<boost::shared_mutex> activeKeyFramelock;
    const float*                            activeKeyFrameImageData;
    bool                                    activeKeyFrameIsReactivated;

    // Pointer to the previous support frame
	Frame* oldest_referenceFrame;

    // Pointer to the new support frame
	Frame* newest_referenceFrame;

    // Pointers to support frames
	std::vector<Frame*> referenceFrameByID;

    // Some offset
	int referenceFrameByID_offset;

    // ============= Internally used buffers for intermediate calculations etc. =============
    // For internal depth tracking, their memory is managed (created & deleted) by this object.
    DepthMapPixelHypothesis*    m_poOtherDepthMap;
    DepthMapPixelHypothesis*    m_poCurrentDepthMap;

    int*                        m_pnValidityIntegralBuffer;

	
	// ============ internal functions ==================================================
    // Does the line-stereo seeking.
	// takes a lot of parameters, because they all have been pre-computed before.
    inline float doLineStereo   (   const float     u,                      const float v,
                                    const float     epxn,                   const float epyn,
                                    const float     min_idepth,             const float prior_idepth,
                                          float     max_idepth,             const Frame* const referenceFrame,
                                    const float*    referenceFrameImage,	float &result_idepth,
                                    float           &result_var,            float &result_eplLength,
                                    RunningStats* const stats);


	void propagateDepth(Frame* new_keyframe);

	void observeDepth();
    void observeDepthRow    (       int yMin,       int yMax,   RunningStats* stats);

    bool observeDepthCreate (const  int &x,  const  int &y,     const int &idx, RunningStats* const &stats);

    bool observeDepthUpdate (const  int &x,  const  int &y,     const int           &idx, const float* keyFrameMaxGradBuf, RunningStats* const &stats);
    bool makeAndCheckEPL    (const  int x,   const  int y,      const Frame* const  ref, float* pepx, float* pepy, RunningStats* const stats);

    void regularizeDepthMap             (bool removeOcclusion, int validityTH);

    template<bool removeOcclusions>
    void regularizeDepthMapRow(int validityTH, int yMin, int yMax, RunningStats* stats);

    void buildRegIntegralBuffer         ();
    void buildRegIntegralBufferRow1     ( int yMin, int yMax, RunningStats* stats );

    void regularizeDepthMapFillHoles    ();
    void regularizeDepthMapFillHolesRow ( int yMin, int yMax, RunningStats* stats );


	void resetCounters();

	//float clocksPropagate, clocksPropagateKF, clocksObserve, msObserve, clocksReg1, clocksReg2, msReg1, msReg2, clocksFinalize;
};

}
