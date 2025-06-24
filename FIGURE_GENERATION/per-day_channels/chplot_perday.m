%% ~~~~~~~~~~~~~~~~ Plot per-day continuous channel traces ~~~~~~~~~~~~~~~~
%{
    The following script imports .mat file containing a single channel's
    trace, prepares it, and plots it. Mat files are
    expected to be named "c{channel_number}" and contain a 1-by-N array of
    doubles, where N is the number of samples recorded. The variable
    'dir_trac' (line 41) must be changed to point to the containing
    directory.
    
    The script also assumes that recordings were done in the Open Ephys GUI
    as it uses the .oebin file to get the 'bit_volts' multiplier and
    multiplies the entire trace by that number to accurately represent the
    signal scale.

    Several channels can be plotted in a single figure by setting the
    "channs_of_interest" variable to the desired channel numbers (see line
    78). This will create a Mx1 figure where M is the number of channels
    plotted.
    
    You may also change the length of the plotted signal by setting the
    variable 'samples_toplot' (line 85).

    Data can be plotted directly if the appropriate data has already been
    produced (f.e. if the data was downloaded from
    www.github.com/rjibanezalcala/EXPLORE) bby running the block titled
    "Plot channels" (line 117), though 'filename_day_ch' must point to the
    correct directory (line 123).

    For preprocessing and spike detection code, please see the repository
    linked below:
    https://github.com/lddavila/cluster_neuronspikes/tree/main/Porting%20Open%20Ephys 
%}
%% Set directories
% Root directory where the data is stored
dir_root = "F:\Electrophysiology Data (OpenEphys)\Steven";

% Data directories
dir_day  = strcat( dir_root, "\2024-12-03_17-01-27__Steven");
dir_data = strcat( dir_day , "\Raw Recordings");
dir_prec = strcat( dir_data, "\Precomputed");
dir_trac = strcat( dir_prec, "\average butterworth");

% Metadata (Oebin file) directory
node       = 103;
experiment = 1;
recording  = 1;
dir_oebn   = dir_day+"\Record Node "+string(node)+"\experiment"...
                +string(experiment)+"\recording"...
                +string(recording)+"\structure.oebin";
% Read metadata file
fileID = fopen(dir_oebn, 'r');
oebin  = fread(fileID, inf, 'uint8=>char')';
fclose(fileID);
% Parse the JSON content to get the bit_volts parameters which allows us to
% convert bits to volts.
oebinStruct = jsondecode(oebin);
% struct_with_bit_volts = oebinStruct.continuous.channels;
bit_volts = [oebinStruct.continuous.channels(:).bit_volts] * -1; % * -1 inverts the recordings

% Get days since surgery (set by d0)
d0 = datetime("2024-09-12"); % Day of surgery (yyy-mm-dd)
% Get the current recording's date (from dir_day)
dn  = split(dir_day, "\");
dn  = split(dn(end), "_");
dn  = datetime(dn(1));
day = between(d0,dn,'days');

% Clean up
clear node;
clear experiment;
clear recording;
clear fileID;
clear oebin;

%% Import and cut recordings to size for visualising in paper (250 ms chunks)

% Select channels of interest only and generate a list of channels
channs_of_interest = 30:36; % Change this as needed!
list_of_channels = strcat("c",string(channs_of_interest));

% Prepare to filter whole trace to only a few samples
sample_freq    = oebinStruct.continuous.sample_rate;            % In Hz
sample_period  = sample_freq ^ -1; % In seconds, same as '1/sample_freq'
time_window    = 0.250;            % Seconds
samples_toplot = time_window / sample_period;
index_start    = 1;
index_end      = (index_start - 1) + samples_toplot;

% Create empty container to import data into
channels = zeros(length(channs_of_interest), samples_toplot);

% Convert to row array to iterate through elements directly
i = 1;       % Just an iterating variable
for x = list_of_channels(:).'
    % Grab data
    data = importdata(dir_trac + "\" + x + ".mat");
    % Populate matrix row with the target data samples
    % channels(i, :) = double (data([index_start : index_end]) ) * bit_volts(1); 
    channels(i, :) = double (data([index_start : index_end]) ); % If data was produced already wth bit_volts.
    % Move to the next matrix row and data file
    i = i + 1;
end

% Clean up
clear data;
clear x;
clear i;

%% Save data (just in case)
filename_day_ch = strcat(dir_prec, "\",...
     "Channels_", string(channs_of_interest(1)),"-",...
     string(channs_of_interest(length(channs_of_interest))),...
     "_", string(time_window*1000), "ms",...
     "_", string(day), ".mat");
save(filename_day_ch, "channels");

%% Plot channels
% This block will plot all channels of interest in the same plot. Do not
% run this if you have more than 7 channels to plot!

% -------- Grab data ---------
if ~exist('channels','var')
    channels = load(filename_day_ch).channels;
end

% -------- Prepare y-axis --------
% Record maximum and minimum values in dataset (for y-axis limits)
min_max = [0, 0];  % Maximum and minumum values in the dataset
for i = 1:size(channels, 1)
    if min( channels(i, :) ) < min_max(1)
        min_max(1) = floor( min( channels(i, :) ) );
    end
    if max( channels(i, :) ) > min_max(2)
        min_max(2) = ceil( max( channels(i, :) ) );
    end
end
% Round the result to the nearest tenth
% min_max = [floor(min_max(1)/10)*10, ceil(min_max(2)/10)*10];
% Round to the nearest hundredth
min_max = [floor(min_max(1)/100)*100, ceil(min_max(2)/100)*100];
% -------- Prepare x axis --------
ts_start = 1 * sample_period; % First timestamp
ts_end   = samples_toplot * sample_period; % Last timestamp
x = linspace( ts_start, ts_end, size(channels, 2) );

% -------- Start plotting --------
t = tiledlayout( length(channs_of_interest), 1 );
for i = 1:size(channels, 1)
    y = channels(i, :);
    nexttile
    plot(x, y);
    ylim(min_max);
    yticks(min_max);
    title( strcat("Channel ", string(channs_of_interest(i))) );
    xlabel( t, strcat("Time (", string(time_window * 1000), " ms)"),...
        'FontWeight','bold' );
    ylabel( t, "μV (Inverted)", 'FontWeight','bold' );
end

%% Save figure
% Construct filename
filename_fig = strcat("Channels_", string(channs_of_interest(1)),"-",...
    string(channs_of_interest(length(channs_of_interest))),...
    "_", string(time_window*1000), "ms", "_",...
    string(day), ".svg");
% Export figure
% exportgraphics(t, strcat(dir_prec, filename_fig),...
%     'BackgroundColor','none',...
%     'ContentType','vector');