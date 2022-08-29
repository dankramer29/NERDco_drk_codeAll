classdef (Enumeration) DecoderConstants < Simulink.IntEnumType
%    properties (Constant)
    enumeration
        %% STATE MACHINE CONSTANTS
        NO_TRANSFORM(0)
        SQRT_TRANSFORM(1)
        DECODER_TYPE_VFBSSKF(1)
        DECODER_TYPE_PCAVFBSSKF(26)
        DECODER_TYPE_VFBNORMSSKF(27)
        NUM_KINEMATIC_DIMENSIONS(2) %SNF: excuse me? Why is this 2? clearly unused 
        %SNF: these should be equations based on num chans per array * num arrays but okay
        NUM_SPIKE_CHANNELS(192) % upgraded to dual-array
        NUM_HLFP_CHANNELS(192) % upgraded to dual-array
        NUM_CONTINUOUS_CHANNELS(384) % upgraded to dual-array. SNF: this is a misnomer, this really just means "num_channels" for disc and cont
        NUM_CHANNELS_PER_ARRAY(96)
        HLFP_DIVISOR(500) % divide hLFP gamma power-time by this to bring it closer to spike count range to keep C from being badly scaled
        
        MAX_DISCRETE_STATES(6) %SNF: changed from 3 to 6 for Multiclick3- move + idle + 4 clicks = 6 states possible. 
        MAX_DISCRETE_DECODE_CHANNELS(20) % SNF: this is the... num dims? idk why this is 20
        MAX_KERNEL_LENGTH(200)

        DISCRETE_DECODER_TYPE_HMMPCA(1)
        DISCRETE_DECODER_TYPE_HMMFA(2)
        DISCRETE_DECODER_TYPE_HMMLDA(3)
        
        BIAS_CORRECTION_CPPN(0)
        BIAS_CORRECTION_FRANK(1) % squares each dimension before accumulating it into bias estimate
        BIAS_CORRECTION_BEATA(2) % linearly adds each dimension before accumulating it into bias estimate
        BIAS_CORRECTION_SERGEY(3) % normalizes high-D speed to threshold, then squares, then reverses normalization, then accumulates
        
        NUM_HMM_SPEED_BINS(10) % speed scaling -> number of bins
    end
end