# FactoryX Radio DJ
  
  
# <u>Dependencies</u> 
  
- MfPack Version 4.0.0 or higher 
- Delphi XE2 (minimum recommended version: Delphi XE7) up to and including Delphi 13.1  
  
  
**Important note:**  
The latest Windows 11 versions do not support Dolby AC-3 and H.265 (hvec) encoders.  
Those you can buy from Microsoft Store or download elsewhere.  
  
  
**MfRDJ Radio Mixer**  
This application is a multi-channel audio mixer with effects able to use IceCast/Caddy for internet broadcasting.  
The Mixer is fully adjustable for audio endpoint assignments, mixer decks and loopback decks.  
  
**Note:**  
 Before compiling this sample make sure, you have all needed components installed first (see instructions).  
  
![](https://github.com/FactoryXCode/FactoryX-Radio-DJ/blob/main/Pic/RDJ_Interface_s.png)
  
  
**MfRDJ Pro Radio Mixer**  
MfRDJPro is the extended version of MfRDJ.
  
Where MfRDJ mainly demonstrates DJ-style audio playback and mixing with MfPack,  
MfRDJ Pro adds a complete live broadcast layer around the mixer.  
MfRDJ Pro still provides the familiar RDJ functions: channel decks,  
loopback decks, microphone input, effects, PFL/cue monitoring, playlist editing,  
tag editing, and local recording.  
  
The Pro version expands this into an audio/video streaming application.  
It can combine the live program audio with camera video or a static video source,  
encode the result with Microsoft Media Foundation, and publish it as a browser-playable stream.  

The main technical difference is the broadcast pipeline.  
MfRDJ Pro uses Media Foundation Sink Writer and the MPEG-4 media sink to create fragmented MP4.
MfRDJ Pro observes the generated MP4 byte stream, extracts and patches fMP4 fragments,
writes a rolling live.json manifest, and serves the result through FxServe or an alternative proxy server like Caddy.
Modern browsers can then play the stream using Media Source Extensions.
MfRDJ Pro also writes now-playing metadata, artwork links, on-air state, and 
listener counts to JSON files for the web interface.

It includes safeguards for long-running broadcasts, such as bounded queues,  
fragment cleanup, FxServe mirroring, sleep prevention options, and clean shutdown handling.  
MfRDJ Pro supports casting to Cromecast devices on your local network using the  
MfPack Cast V2 protocols. 

An extra tool FxRecord is provided for broadcast stations that needs to record their broadcasts by law.
  
**Note:**  
Before using this sample make sure, you have all needed components installed (see instructions).  
  
![](https://github.com/FactoryXCode/FactoryX-Radio-DJ/blob/main/Pic/RDJPro_Interface_s.png)
  
---
  
**(c) FactoryX. All rights reserved.**
