# -*- coding: utf-8 -*-
"""
Created on Tue May 20 16:36:36 2025

@author: Raquel Ibáñez Alcalá

This script imports a .csv file and plots individual parts
of it.

Expects a CSV file with the following data structure:
    
 -------------------------------------------------------------------------------------
| Index | Channel | Amplitude | Spike_Idx | Waveform_1 ... _51 | Timestamps_1 ... _51 |
|-------|---------|-----------|-----------|--------------------|----------------------|
| int   | int     | float     | int       | float              | float                |
 -------------------------------------------------------------------------------------

"""

# import scipy.io as sio
import matplotlib.pyplot as plt
# import numpy
import pandas as pd
from os import path, getcwd, listdir, mkdir

# %% Nevermind the stinky matlab file I'm doing CSV

# mat_file = r"spike_table"

# mat = sio.loadmat(mat_file, variable_names='None')
# keys = [x for x in mat.keys() if not x.startswith("__")]

# %% Define environment variables and functions
# cwd = path.abspath('{D:\PATH\TO\DATA}')
cwd = path.abspath(getcwd())
file = cwd+r"\spike_data_filtered.csv"
save_ext = r'.svg'
save_loc = cwd+r'\Figures'
save_idx = []
metadata = {
    'Index': '',
    'Channel': '',
    'Spike_Idx':'',
    'Amplitude':''
    }

# Create folder to save figures to if it doesn't exist
if not path.isdir( path.abspath( save_loc ) ):
    mkdir( path.abspath( save_loc ) )

def get_saved(filepath, ext, last_idx):
    try:
        files = [ name for name in listdir(filepath) if name.endswith(ext) ]
        result = []
        for x in files:
            result.append(
                int(x.split('_')[0].split('o')[1])
                )
    except IndexError:
        print(f"\nNo saved figures found in {filepath}.\nCould not generate range.\n")
        return (None, None)
    else:
        try:
            final = (range(result[-1]+1, last_idx), sorted(result))
        except IndexError:
            print(f"\nNo saved figures found in {filepath}.\nCould not generate range.\n")
            return (None, None)
        else:
            return final

def plot_spike(x, y, height=5, width=6, tick_size=6, label_size=7, show=True):
    xlength = round((x[len(x)-1] - x[0])*1000, 1)
    
    fig, ax = plt.subplots()
    fig.set_figwidth(width)
    fig.set_figheight(height)
    ax.plot(x, y)
    ax.spines[['top', 'right']].set_visible(False)
    ax.tick_params(axis='both', which='both', length=0)
    plt.xticks(fontsize=tick_size)
    ax.set_box_aspect(1)
    plt.tight_layout()
    plt.xlabel(f"Time ({str(xlength)} ms)", fontweight = 'bold', fontsize=label_size)
    plt.ylabel("μV (inverted)", fontweight = 'bold', fontsize=label_size)
    plt.xticks([])
    plt.yticks([min(y), 0, max(y)])
    
    figure = fig
    plt.show()
    
    return figure

def save_spike(loc, fig, metadata, ext, usr_dpi=300, trans=True):
    i = metadata['Index']
    chan = metadata['Channel']
    spk_idx = metadata['Spike_Idx']
    amplitude = metadata['Amplitude']
    
    filepath = loc+ '\\' + f"No{i}_Ch{str(chan)}_SpkNo{str(spk_idx)}_Amp{str(round(amplitude))}{ext}"
    
    plot.savefig(filepath,
        transparent=trans,
        dpi=usr_dpi)
    
    return

# %% Import data

# Import csv
spikes = pd.read_csv(file)

# %% Fix the mess (if any)
"""
For some reason, MatLab exported the csv table in a way where it
separated every single element of the "waveform" and "timestamps"
columns. Thus, I try to merge them back together here. You may
omit this block if the data you're using is already cleaned.
"""

# Identify the problem columns
waveform_cols = [head for head in spikes.columns if head.startswith("Waveform")]
timestmp_cols = [head for head in spikes.columns if head.startswith("Timestamps")]

# Merge timestamp and waveform cols
spikes['Waveform'] = spikes[waveform_cols].values.tolist()
spikes['Timestamps'] = spikes[timestmp_cols].values.tolist()

# Drop the problem columns
spikes = spikes.drop(waveform_cols+timestmp_cols, axis=1)

# %% Ranges
"""
Set up ranges of plot indecies to iterate thru (in case you need to re-plot
existing figures or continue from where you left off). If you downloaded the
CSV table from GitHub, use 'all'.
"""

rnge = {
       # Start from index 0 of spike dataset    
       'all':      range(len(spikes)),
       # Only iterate thru plots that have already been saved
       'saved':    get_saved(save_loc, save_ext, len(spikes))[1],
       # Continue from the last saved plot
       'continue': get_saved(save_loc, save_ext, len(spikes))[0]
       }

# %% Plotting
"""
Visualise the waveforms. Will give you the choice to save the current figure,
continue to the next one, or exit every time.
"""
save_idx = []
# Set True if you want to just save the figures
autosave = False

# Change the key in 'rnge' to one of the options in lines 125 - 132.
for i in rnge['all']:
    try:
        x = spikes['Timestamps'][i]
        y = spikes['Waveform'][i]
        
        plot = plot_spike(x,y)
        
    except Exception as e:
        print(f"The following error occurred: {e}")
    else:
        print(f"Spike number {str(i)}")
        if autosave:
            metadata.update({
                'Index':    i,
                'Channel':  spikes['Channel'][i],
                'Spike_Idx':spikes['Spike_Idx'][i],
                'Amplitude':spikes['Amplitude'][i]
                })
            
            save_spike(save_loc, plot, metadata, save_ext)
        else:
            keypress = input("{Enter} to continue, {s} to save plot, {x} to exit\n")
            if keypress == 's':
                metadata.update({
                    'Index':    i,
                    'Channel':  spikes['Channel'][i],
                    'Spike_Idx':spikes['Spike_Idx'][i],
                    'Amplitude':spikes['Amplitude'][i]
                    })
                
                save_spike(save_loc, plot, metadata, save_ext)
    
                save_idx.append(i)
            elif keypress == 'x':
                break
s = get_saved(save_loc, save_ext)
print(f"\nThe following spikes are currently in {save_loc} (total of {str(len(s))}):")
print(s)
print(f"\nThe following spikes were saved this session (total of {str(len(save_idx))}:")
print(save_idx)

