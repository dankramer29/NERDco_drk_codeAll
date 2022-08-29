#include <math.h>
#include "mex.h"
#include "simulator.h"
#include "pwl_interp_1d.h"

#define PI 3.14159265

double euclidianDistance(double *x, double *y, int nElements);
double euclidianNorm(double *x, int nElements);
void nonlinIntegrate(int nElements, double *pos, double *newPos, double *vel, double loopTime, struct simPlant *plant); 

void simulate(struct simulator *sim)
{
    int done=0;
    int xMatElement = 2 * sim->plant.nDim * sim->loopIdx;
    int xMatDelayedElement = 2 * sim->plant.nDim * (sim->loopIdx - sim->forwardModel.delaySteps - 1);
    int uMatElement = sim->plant.nDim * sim->loopIdx;
    int uMatDelayedElement = sim->plant.nDim * (sim->loopIdx - sim->forwardModel.delaySteps - 1);
    
    double timeInTarget=0;
    double targDist=0;
    
    double targDistHat=0;
    double speedHat=0;
    double posErrHat[MAX_DIM];
    double cVecNorm=0;
    
    double fTargWeight=0;
    double fVelWeight=0;
    double noiseWeight=0;
    double targComponent=0;
    double velComponent=0;
    double deadzoneToUse=0;
    double smoothComponent=0;
    
    double angle=0;
    double prevAngle=0;
    double angDiff = 0;
    
    int nLoops = 1;
    int i;
    int j;
    int x;
    
    if(sim->control.targetDeadzone==-1)
    {
        deadzoneToUse = sim->trial.targRad;
    }
    else
    {
        deadzoneToUse = sim->control.targetDeadzone;
    }
    
    while(!done){
        //forward model

        memcpy(&(sim->xHatMatrix[xMatElement]), &(sim->xMatrix[xMatDelayedElement]), 2 * sim->plant.nDim * sizeof(double)); 
        for(i=0; i<sim->forwardModel.forwardSteps; i++){
            //velocity
            for(j=0; j<sim->plant.nDim; j++){
                //new_velocity = alpha*previous_velocity + beta*(1-alpha)*decoded_control_vector
                sim->xHatMatrix[xMatElement + sim->plant.nDim + j] = sim->plant.alpha * sim->xHatMatrix[xMatElement + sim->plant.nDim + j] + 
                    sim->plant.beta * (1-sim->plant.alpha) * sim->cMatrix[uMatDelayedElement + j + i*sim->plant.nDim];
            }
            
            nonlinIntegrate(sim->plant.nDim, &(sim->xHatMatrix[xMatElement]), &(sim->xHatMatrix[xMatElement]), 
                    &(sim->xHatMatrix[xMatElement + sim->plant.nDim]), sim->loopTime, &(sim->plant));
        }
        
        //control policy
        for(j=0; j<sim->plant.nDim; j++){
            posErrHat[j] = sim->trial.targetPos[j] - sim->xHatMatrix[xMatElement + j];
        }
        targDistHat = euclidianNorm(posErrHat, sim->plant.nDim);
        speedHat = euclidianNorm(&(sim->xHatMatrix[xMatElement + sim->plant.nDim]), sim->plant.nDim);
        
        fTargWeight = pwl_value_1d_scalar(sim->control.nfTarg, sim->control.fTargX, sim->control.fTargY, targDistHat);
        fVelWeight = pwl_value_1d_scalar(sim->control.nfVel, sim->control.fVelX, sim->control.fVelY, speedHat);
        
        for(j=0; j<sim->plant.nDim; j++){
            if(targDistHat==0)
                targComponent=0;
            else
                targComponent=(posErrHat[j]/targDistHat)*fTargWeight;
            
            if(speedHat==0)
                velComponent=0;
            else
                velComponent=(sim->xHatMatrix[xMatElement + sim->plant.nDim + j]/speedHat)*fVelWeight;
            
            sim->cMatrix[uMatElement + j] = targComponent + velComponent;
        }
        
        //target deadzone, or reaction time period, sets control vector to zero
        if((targDistHat <= deadzoneToUse) || (nLoops <= sim->control.rtSteps)){
            for(j=0; j<sim->plant.nDim; j++){
                sim->cMatrix[uMatElement + j] = 0;
            }
        }
        
        //noise
        cVecNorm = euclidianNorm(&(sim->cMatrix[uMatElement]), sim->plant.nDim);
        noiseWeight = pwl_value_1d_scalar(sim->noise.nsdn, sim->noise.sdnX, sim->noise.sdnY, cVecNorm);
        for(j=0; j<sim->plant.nDim; j++){
            sim->uMatrix[uMatElement + j] = sim->cMatrix[uMatElement + j] + (sim->noise.noiseMatrix[sim->noise.noiseIdx*sim->plant.nDim + j])*noiseWeight;
        }
        
        //plant 
        //velocity
        for(j=0; j<sim->plant.nDim; j++){
            //smooth control vector with bCoef FIR filter
            smoothComponent = 0;
            for(x=0; x<sim->plant.nbCoef; x++){
                smoothComponent = smoothComponent + sim->plant.bCoef[x]*sim->uMatrix[uMatElement + j - sim->plant.nDim*x];
            }
                
            //new_velocity = alpha*previous_velocity + beta*(1-alpha)*decoded_control_vector
            sim->xMatrix[xMatElement + sim->plant.nDim + j] = sim->plant.alpha * sim->xMatrix[xMatElement - sim->plant.nDim + j] + 
                    sim->plant.beta * (1-sim->plant.alpha) * smoothComponent;
        }
        
        //position
        nonlinIntegrate(sim->plant.nDim, &(sim->xMatrix[xMatElement - 2*sim->plant.nDim]), &(sim->xMatrix[xMatElement]), 
            &(sim->xMatrix[xMatElement + sim->plant.nDim]), sim->loopTime, &(sim->plant));

        //target acquisition
        targDist = euclidianDistance(&(sim->xMatrix[xMatElement]), sim->trial.targetPos, sim->plant.nDim);
        if(targDist < sim->trial.targRad)
        {
            timeInTarget+=sim->loopTime;
        }
        else if(sim->trial.continuousHoldRule)
        {
            timeInTarget=0;
        }
        
        if((timeInTarget>=sim->trial.dwellTime) || ((nLoops * sim->loopTime) >= sim->trial.maxTrialTime))
            done = 1;
        
        //increment array indices
        nLoops = nLoops + 1;
        
        xMatElement = xMatElement + 2 * sim->plant.nDim; 
        xMatDelayedElement = xMatDelayedElement + 2 * sim->plant.nDim; 
        uMatElement = uMatElement + sim->plant.nDim; 
        uMatDelayedElement = uMatDelayedElement + sim->plant.nDim; 
        sim->loopIdx = sim->loopIdx + 1;
        
        sim->noise.noiseIdx += 1;
        if(sim->noise.noiseIdx >= sim->noise.nColsForNoiseMatrix)
            sim->noise.noiseIdx = 0;
    }
}

double euclidianDistance(double *x, double *y, int nElements){
    double tmp=0;
    int i;
    
    for(i=0; i<nElements; i++){
        tmp = tmp + (x[i]-y[i])*(x[i]-y[i]);
    }
    return sqrt(tmp);
}

double euclidianNorm(double *x, int nElements){
    double tmp=0;
    int i;
    for(i=0; i<nElements; i++){
        tmp = tmp + x[i]*x[i];
    }
    return sqrt(tmp);
}

//integrates the cursor velocity into cursor position, while potentially applying some simple non-linear transformations
void nonlinIntegrate(int nElements, double *pos, double *newPos, double *vel, double loopTime, struct simPlant *plant){
    int j;
    double speed;
    double newSpeed;
    double speedRatio;
    double weightedAverageSpeed;
    
    double multiplier;
    double offset;
    double velScaled;
    
    if(plant->nonlinType==0){
        for(j=0; j<nElements; j++){
            //linear pass through
            newPos[j] = pos[j] + loopTime * vel[j];
        } 
    }
    else if(plant->nonlinType==1){
        //exponentiate the speed
        speed = euclidianNorm(vel, nElements);
        speed = pow(speed, plant->n1);
        for(j=0; j<nElements; j++){
            newPos[j] = pos[j] + loopTime * vel[j] * speed;
        }  
    }
    else if(plant->nonlinType==2){
        //threshold the speed
        speed = euclidianNorm(vel, nElements);
        newSpeed = speed - plant->n1;
        if(newSpeed<0){
            newSpeed = 0;
        }
        if(speed==0){
            speedRatio = 1;
        }
        else{
            speedRatio = newSpeed/speed;
        }
        
        for(j=0; j<nElements; j++){
            newPos[j] = pos[j] + loopTime * vel[j] * speedRatio;
        }  
    }
    else if(plant->nonlinType==3){
        //static nonlinearity
        speed = euclidianNorm(vel, nElements);
        newSpeed = pwl_value_1d_scalar(plant->nfStatic, plant->fStaticX, plant->fStaticY, speed);
        if(speed==0){
            speedRatio = 1;
        }
        else{
            speedRatio = newSpeed/speed;
        }
        
        for(j=0; j<nElements; j++){
            newPos[j] = pos[j] + loopTime * vel[j] * speedRatio;
        }  
    }
    else if(plant->nonlinType==4){
        //Sergey component-wise exponential nonlinearity
        //n1 = gain base
        //n2 = unity crossing
        for(j=0; j<nElements; j++){
            velScaled = fabs(vel[j]/plant->n2);
            offset = 1/plant->n1;
            multiplier = 1/(1-offset);
            velScaled = multiplier*(pow(plant->n1, velScaled-1)-offset)*plant->n2;
            if(vel[j]<0)
                velScaled = -velScaled;
            newPos[j] = pos[j] + loopTime * velScaled;
        }  
    }
    else if(plant->nonlinType==5){
        //Sergey speed-wise exponential nonlinearity
        //n1 = gain base
        //n2 = unity crossing
        speed = euclidianNorm(vel, nElements);
        
        newSpeed = speed/plant->n2; 
        offset = 1/plant->n1;
        multiplier = 1/(1-offset);
        newSpeed = multiplier*(pow(plant->n1, newSpeed-1)-offset)*plant->n2;
        
        if(speed==0){
            speedRatio = 1;
        }
        else{
            speedRatio = newSpeed/speed;
        }
        
        for(j=0; j<nElements; j++){
            newPos[j] = pos[j] + loopTime * vel[j] * speedRatio;
        }  
    }
}

