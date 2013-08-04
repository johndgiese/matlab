function [ConvertedData,ConvertVer]=convertTDMS(SaveConvertedFile,filename)

%Function to load LabView TDMS data file(s) into variables in the MATLAB workspace.
%An *.MAT file can also be created.  If called with one input, the user selects
%a data file.  This function was submitted to MATLAB Central's File Exchange by
%Robert Seltzer on 1 SEP 10.
%
%   TDMS format is based on information provided by National Instruments
%   at:    http://zone.ni.com/devzone/cda/tut/p/id/5696
%
% [ConvertedData,Index,ConvertVer]=convertTDMS(SaveConvertedFile,filename);
%
%       Inputs:
%               SaveConvertedFile (required) - Logical flag (true/false) that
%                 determines whether a MAT file is created.  The MAT file's name
%                 is the same as 'filename' except that the 'TDMS' file extension is
%                 replaced with 'MAT'.  The MAT file is saved in the same folder
%                 and will overwrite an existing file without warning.  The
%                 MAT file contains all the output variables.
%
%               filename (optional) - Filename (fully defined) to be converted.
%                 If not supplied, the user is provided dialog box to open file.
%                 Can be a cell array of files for bulk conversion.
%
%       Outputs:
%               ConvertedData (required) - Structure with all of the data objects.
%               ConvertVer (required) - the version number of this function.
%

%---------------------------------------------
%Brad Humphreys - v1.0 2008-04-23
%ZIN Technologies
%---------------------------------------------

%---------------------------------------------
%Brad Humphreys - v1.1 2008-07-03
%ZIN Technologies
%-Added abilty for timestamp to be a raw data type, not just meta data.
%-Addressed an issue with having a default nsmaples entry for new objects.
%-Added Error trap if file name not found.
%-Corrected significant problem where it was assumed that once an object
%    existsed, it would in in every subsequent segement.  This is not true.
%---------------------------------------------

%---------------------------------------------
%Grant Lohsen - v1.2 2009-11-15
%Georgia Tech Research Institute
%-Converts TDMS v2 files
%Folks, it's not pretty but I don't have time to make it pretty. Enjoy.
%---------------------------------------------

%---------------------------------------------
%Jeff Sitterle - v1.3 2010-01-10
%Georgia Tech Research Institute
%Modified to return all information stored in the TDMS file to inlcude
%name, start time, start time offset, samples per read, total samples, unit
%description, and unit string.  Also provides event time and event
%description in text form
%Vast speed improvement as save was the previous longest task
%---------------------------------------------

%---------------------------------------------
%Grant Lohsen - v1.4 2009-04-15
%Georgia Tech Research Institute
%Reads file header info and stores in the Root Structure.
%---------------------------------------------

%---------------------------------------------
%Robert Seltzer - v1.5 2010-07-14
%BorgWarner Morse TEC
%-Tested in MATLAB 2007b and 2010a.
%-APPEARS to now be compatible with TDMS version 1.1 (a.k.a 4712) files;
%	although, this has not been extensively tested.  For some unknown
%	reason, the version 1.2 (4713) files process noticeably faster. I think
%	that it may be related to the 'TDSm' tag.
%-"Time Stamp" data type was not tested.
%-"Waveform" fields was not tested.
%-Fixed an error in the 'LV2MatlabDataType' function where LabView data type
%	'tdsTypeSingleFloat' was defined as MATLAB data type 'float64' .  Changed
%	to 'float32'.
%-Added error trapping.
%-Added feature to count the number of segments for pre-allocation as
%	opposed to estimating the number of segments.
%-Added option to save the data in a MAT file.
%-Fixed "invalid field name" error caused by excessive string lengths.
%---------------------------------------------

%---------------------------------------------
%Robert Seltzer - v1.6 2010-09-01
%BorgWarner Morse TEC
%-Tested in MATLAB 2010a.
%-Fixed the "Coversion to cell from char is not possible" error found
%  by Francisco Botero in version 1.5.
%-Added capability to process both fragmented or defragmented data.
%-Fixed the "field" error found by Lawrence.
%---------------------------------------------

%Initialize outputs
ConvertVer='1.6';    %Version number of this conversion function
ConvertedData=[];

switch nargin
	case 0
		e=errordlg('The function requires at least 1 input argument','Insufficient Input Arguments');
		uiwait(e)
		return
		
	case 1
		
		if ~islogical(SaveConvertedFile)
			if ~ismember(SaveConvertedFile,[0,1])
				e=errordlg('The function''s input argument must be ''True'' or ''False''','Invalid Input Argument');
				uiwait(e)
				return
			end
		end
		
		%Prompt the user for the file
		[filename,pathname,filterindex]=uigetfile({'*.tdms','All Files (*.tdms)'},'Choose a TDMS File');
		if filename==0
			return
		end
		filename=fullfile(pathname,filename);
		infilename=cellstr(filename);
		
	case 2
		
		if ~islogical(SaveConvertedFile)
			if ~ismember(SaveConvertedFile,[0,1])
				e=errordlg('The function''s first input argument must be ''True'' or ''False''','Invalid Input Argument');
				uiwait(e)
				return
			end
		end
		
		if ~ischar(filename) && ~iscell(filename)
			e=errordlg(['The function''s second input argument (file list) must be either a character string for 1 file '...
				'or a cell array of 1 or more files'],'Invalid Input Argument');
			uiwait(e)
			return
		end
		
		if iscell(filename)
			%For a list of files
			infilename=filename;
		else
			infilename=cellstr(filename);
		end
		
	otherwise
		e=errordlg('The function requires 1 or 2 input arguments','Too Many Input Arguments');
		uiwait(e)
		return
		
end

for fnum=1:numel(infilename)
	
	if ~exist(infilename{fnum},'file')
		e=errordlg(sprintf('File ''%s'' not found.',infilename{fnum}),'File Not Found');
		uiwait(e)
		return
	end
	
	FileNameLong=infilename{fnum};
	[pathstr,name,ext]=fileparts(FileNameLong);
	FileNameShort=sprintf('%s%s',name,ext);
	FileNameNoExt=name;
	FileFolder=pathstr;
	
	if fnum==1
		fprintf('\n\n')
	end
	fprintf('Converting ''%s''...',FileNameShort)
	
	fid=fopen(FileNameLong);
	if fid==-1
		e=errordlg(sprintf('Could not open ''%s''.',FileNameLong),'File Cannot Be Opened');
		uiwait(e)
		fprintf('\n\n')
		return
	end
	
	%**********************************************************************************************************************
	%Count the number of segments.  While doing the count, also include error trapping.
	%Find the end of the file
	fseek(fid,0,'eof');
	eoff=ftell(fid);
	frewind(fid);
	
	segCnt=0;
	CurrPosn=0;
	LeadInByteCount=28;	%From the National Instruments web page (http://zone.ni.com/devzone/cda/tut/p/id/5696) under
	%the 'Lead In' description on page 2: Counted the bytes shown in the table.
	while (ftell(fid) ~= eoff)
		
		Ttag=fread(fid,1,'uint8');
		Dtag=fread(fid,1,'uint8');
		Stag=fread(fid,1,'uint8');
		mtag=fread(fid,1,'uint8');
		
		if Ttag==84 && Dtag==68 && Stag==83 && mtag==109
			%Apparently, this sequence of numbers identifies the start of a new segment.
			
			segCnt=segCnt+1;
			
			if segCnt==1
				StartPosn=0;
			else
				StartPosn=CurrPosn;
			end
			
			%ToC Field
			ToC=fread(fid,1,'uint32');
			kTocMetaData=bitget(ToC,2);
			kTocNewObject=bitget(ToC,3);
			kTocRawData=bitget(ToC,4);
			kTocInterleavedData=bitget(ToC,6);
			kTocBigEndian=bitget(ToC,7);
			
			if kTocInterleavedData
				e=errordlg(sprintf(['Seqment %.0f within ''%s'' has interleaved data which is not supported with this '...
					'function (%s.m).'],segCnt,TDMSFileNameShort,mfilename),'Interleaved Data Not Supported');
				fclose(fid);
				uiwait(e)
				uiwait
			end
			
			if kTocBigEndian
				e=errordlg(sprintf(['Seqment %.0f within ''%s'' uses the big-endian data format which is not supported '...
					'with this function (%s.m).'],segCnt,TDMSFileNameShort,mfilename),'Big-Endian Data Format Not Supported');
				fclose(fid);
				uiwait(e)
				uiwait
			end
			
			%TDMS format version number
			vernum=fread(fid,1,'uint32');
			if ~ismember(vernum,[4712,4713])
				e=errordlg(sprintf(['Seqment %.0f within ''%s'' used LabView TDMS file format version %.0f which is not '...
					'supported with this function (%s.m).'],segCnt,TDMSFileNameShort,vernum,mfilename),...
					'TDMS File Format Not Supported');
				fclose(fid);
				uiwait(e)
				uiwait
			end
			
			%From the National Instruments web page (http://zone.ni.com/devzone/cda/tut/p/id/5696) under the
			%'Lead In' description on page 2:
			%The next eight bytes (64-bit unsigned integer) describe the length of the remaining segment (overall length
			%of the segment minus length of the lead in). If further segments are appended to the file, this number can be
			%used to locate the starting point of the following segment. If an application encountered a severe problem
			%while writing to a TDMS file (crash, power outage), all bytes of this integer can be 0xFF. This can only
			%happen to the last segment in a file.
			segLength=fread(fid,1,'uint64');
			metaLength=fread(fid,1,'uint64');
			TotalLength=segLength+LeadInByteCount;
			CurrPosn=CurrPosn+TotalLength;
			
			SegInfo(segCnt).SegStartPosn=StartPosn;
			SegInfo(segCnt).MetaStartPosn=StartPosn+LeadInByteCount;
			SegInfo(segCnt).DataStartPosn=SegInfo(segCnt).MetaStartPosn+metaLength;
			
			fseek(fid,CurrPosn,'bof');		%Move to the beginning position of the next segment
		end
		
	end
	NumOfSeg=segCnt;
	%**********************************************************************************************************************
	
	%Initialize variables for the file conversion
	ob=[];
	for segCnt=1:NumOfSeg
		
		fseek(fid,SegInfo(segCnt).SegStartPosn,'bof');
		
		Ttag=fread(fid,1,'uint8');
		Dtag=fread(fid,1,'uint8');
		Stag=fread(fid,1,'uint8');
		mtag=fread(fid,1,'uint8');
		
		%ToC Field
		ToC=fread(fid,1,'uint32');
		kTocMetaData=bitget(ToC,2);
		kTocNewObject=bitget(ToC,3);
		kTocRawData=bitget(ToC,4);
		kTocInterleavedData=bitget(ToC,6);
		kTocBigEndian=bitget(ToC,7);
		
		vernum=fread(fid,1,'uint32');							%TDMS format version number
		
		segLength=fread(fid,1,'uint64');
		
		metaLength=fread(fid,1,'uint64');
		
		%Process Meta Data
		if kTocMetaData
			clear index
			
			numObjInSeg=fread(fid,1,'uint32');
			
			for q=1:numObjInSeg
				
				obLength=fread(fid,1,'uint32');					%Get the length of the objects name
				obname=fread(fid,obLength,'uint8=>char')';	%Get the objects name
				
				%Fix Object Name
				if strcmp(obname,'/')
					obname='Root';
				else
					[obname,TruncFieldName,ValidFieldName]=fixcharformatlab(obname);
					
					if ~ValidFieldName
						e=errordlg(sprintf('A valid field name could not be created for ''%s''.',obname),...
							'Cannot Create Valid Field Name');
						uiwait(e)
						fclose(fid);
						fprintf('\n\n')
						return
					end
					
					NameUsed=false;
					if exist('index','var')
						if any(strcmpi({index.name},obname))
							NameUsed=true;
						end
					end
					
					if NameUsed
						%The name has already been used.  Add numbers to the end until the name is unique.
						MaxNameLen=namelengthmax;
						if TruncFieldName
							BaseName=obname(1:MaxNameLen);
						else
							BaseName=obname;
						end
						HaveValidName=false;
						NameCount=1;
						while ~HaveValidName
							
							CountStr=sprintf('_%.0f',NameCount);
							
							if TruncFieldName
								NewName=sprintf('%s%s',BaseName(1:(end-numel(CountStr))),CountStr);
							else
								NewName=sprintf('%s%s',BaseName,CountStr);
							end
							
							if numel(NewName)>MaxNameLen
								e=errordlg(sprintf('A unique, valid field name could not be created for ''%s''.',...
									obname),'Cannot Create Valid Field Name');
								uiwait(e)
								fclose(fid);
								fprintf('\n\n')
								return
							end
							
							if all(~strcmpi({index.name},NewName))
								HaveValidName=true;
								if TruncFieldName
									fprintf('\n\n\tField name ''%s'' is too long and\n\t\thas been truncated to ''%s''.\n',...
										obname,NewName)
								else
									fprintf('\n\n\tField name ''%s'' already exits so\n\t\tit has been changed to ''%s''.\n',...
										obname,NewName)
								end
								obname=NewName;
							else
								NameCount=NameCount+1;
							end
						end
					end
				end
				
				%Create the 'index' structure
				if exist('index','var')
					index(end+1).name=obname;
				else
					index.name=obname;
				end
				
				%Validate the object
				if isfield(ob,obname)
					index(end).newob=false;
				else
					ob.(obname)=[];		%Create a blank version of the object
					index(end).newob=true;
				end
				
				%Get the raw data Index
				rawdataindex=fread(fid,1,'uint32');
				if rawdataindex==0
					%No raw data assigned to this object in this segment
					index(end).rawdataindex=rawdataindex;
					index(end).dataType=0;
					index(end).arrayDim=0;
					index(end).nValues=0;
					index(end).byteSize=0;
					index(end).rawDataInThisSeg=false;
				elseif rawdataindex+1==2^32
					%Objects raw data index matches previous index - no changes.  The root object will always have an
					%FFFFFFFF entry
					if strcmpi(index(end).name,'Root')
						index(end).rawdataindex=0;
						index(end).rawDataInThisSeg=false;
					else
						%Need to account for the case where an object (besides the 'root') is added that has no data but
						%reports using previous.
						if index(end).newob
							index(end).rawdataindex=0;
							index(end).rawDataInThisSeg=false;
						else
							if kTocRawData
								index(end).rawdataindex=index(end-1).rawdataindex;
								index(end).rawDataInThisSeg=true;
							else
								index(end).rawdataindex=0;
								index(end).rawDataInThisSeg=false;
							end
						end
					end
				else
					%Get new object information
					index(end).rawdataindex=rawdataindex;
					index(end).dataType=fread(fid,1,'uint32');
					index(end).arrayDim=fread(fid,1,'uint32');
					index(end).nValues=fread(fid,1,'uint64');
					if index(end).dataType==32
						%Datatype is a string
						index(end).byteSize=fread(fid,1,'uint64');
					else
						index(end).byteSize=0;
					end
					index(end).rawDataInThisSeg=true;
				end
				
				%Get the properties
				index(end).numProps=fread(fid,1,'uint32');
				for p=1:index(end).numProps
					propNameLength=fread(fid,1,'uint32');
					propsName=fread(fid,propNameLength,'uint8=>char')';
					propsName=fixcharformatlab(propsName);
					propsDataType=fread(fid,1,'uint32');
					propExists=isfield(ob.(obname),propsName);
					dataExists=isfield(ob.(obname),'data');
					
					if dataExists
						%Get number of data samples for the object in this segment
						nsamps=ob.(obname).nsamples+1;
					else
						nsamps=0;
					end
					
					if propsDataType==32
						%String data type
						propsValueLength=fread(fid,1,'uint32');
						propsValue=fread(fid,propsValueLength,'uint8=>char')';
						if propExists
							if isfield(ob.(obname).(propsName),'cnt')
								cnt=ob.(obname).(propsName).cnt+1;
							else
								cnt=1;
							end
							ob.(obname).(propsName).cnt=cnt;
							ob.(obname).(propsName).value{cnt}=propsValue;
							ob.(obname).(propsName).samples(cnt)=nsamps;
						else
							if strcmp(obname,'Root')
								%Header data
								ob.(obname).(propsName)=propsValue;
							else
								ob.(obname).(propsName).cnt=1;
								ob.(obname).(propsName).value=cell(nsamps,1);		%Pre-allocation
								ob.(obname).(propsName).samples=zeros(nsamps,1);	%Pre-allocation
								if iscell(propsValue)
									ob.(obname).(propsName).value(1)=propsValue;
								else
									ob.(obname).(propsName).value(1)={propsValue};
								end
								ob.(obname).(propsName).samples(1)=nsamps;
							end
						end
					else
						%Numeric data type
						if propsDataType==68
							%Timestamp data type
							tsec=fread(fid,1,'uint64')/2^64+fread(fid,1,'uint64');	%time since Jan-1-1904 in seconds
							propsValue=tsec/86400+695422-5/24;	%/864000 convert to days; +695422 days from Jan-0-0000 to Jan-1-1904
						else
							matType=LV2MatlabDataType(propsDataType);
							if strcmp(matType,'Undefined')
								e=errordlg(sprintf('No MATLAB data type defined for a ''Property Data Type'' value of ''%.0f''.',...
									propsDataType),'Undefined Property Data Type');
								uiwait(e)
								fclose(fid);
								return
							end
							propsValue=fread(fid,1,matType);
						end
						if propExists
							cnt=ob.(obname).(propsName).cnt+1;
							ob.(obname).(propsName).cnt=cnt;
							ob.(obname).(propsName).value(cnt)=propsValue;
							ob.(obname).(propsName).samples(cnt)=nsamps;
						else
							ob.(obname).(propsName).cnt=1;
							ob.(obname).(propsName).value=NaN(nsamps,1);			%Pre-allocation
							ob.(obname).(propsName).samples=zeros(nsamps,1);		%Pre-allocation
							ob.(obname).(propsName).value(1)=propsValue;
							ob.(obname).(propsName).samples(1)=nsamps;
						end
					end
					
				end	%'end' for the 'Property' loop
			end	%'end' for the 'Objects' loop
			
		end
		
		%Process Raw Data
		if kTocRawData
			
			%Loop through each of the groups/channels and read the raw data
			fseek(fid,SegInfo(segCnt).DataStartPosn,'bof');
			for r=1:numel(index)
				
				cname=index(r).name;
				
				if index(r).newob && index(r).rawDataInThisSeg
					index(r).newob=false;
					ob.(cname).nsamples=0;
				end
				
				if index(r).rawDataInThisSeg
					
					nvals=index(r).nValues;
					
					if nvals>0
						
						switch index(r).dataType
							
							case 32		%String
								%From the National Instruments web page (http://zone.ni.com/devzone/cda/tut/p/id/5696) under the
								%'Raw Data' description on page 4:
								%String type channels are preprocessed for fast random access. All strings are concatenated to a
								%contiguous piece of memory. The offset of the first character of each string in this contiguous
								%piece of memory is stored to an array of unsigned 32-bit integers. This array of offset values is
								%stored first, followed by the concatenated string values. This layout allows client applications to
								%access any string value from anywhere in the file by repositioning the file pointer a maximum of
								%three times and without reading any data that is not needed by the client.
								
								StrOffsetArray=fread(fid,nvals,'uint32');
								
								data=cell(1,nvals);	%Pre-allocation
								for dcnt=1:nvals
									if dcnt==1
										StrLength=StrOffsetArray(dcnt);
									else
										StrLength=StrOffsetArray(dcnt)-StrOffsetArray(dcnt-1);
									end
									data{1,dcnt}=char(fread(fid,StrLength,'uint8=>char')');
								end
								cnt=nvals;
								
							case 68		%Timestamp
								data=NaN(1,nvals);	%Pre-allocation
								for dcnt=1:nvals
									tsec=fread(fid,1,'uint64')/2^64+fread(fid,1,'uint64');   %time since Jan-1-1904 in seconds
									data(1,dcnt)=tsec/86400+695422-5/24;	%/864000 convert to days; +695422 days from Jan-0-0000 to Jan-1-1904
								end
								cnt=nvals;
								
							otherwise	%Numeric
								matType=LV2MatlabDataType(index(r).dataType);
								if strcmp(matType,'Undefined')
									e=errordlg(sprintf('No MATLAB data type defined for a ''Raw Data Type'' value of ''%.0f''.',...
										index.dataType(r)),'Undefined Raw Data Type');
									uiwait(e)
									fclose(fid);
									return
								end
								[data,cnt]=fread(fid,nvals,matType);
						end
						
						if isfield(ob.(cname),'nsamples')
							ssamples=ob.(cname).nsamples;
						else
							ssamples=0;
						end
						
						ob.(cname).data(ssamples+1:ssamples+cnt,1)=data;
						ob.(cname).nsamples=ssamples+cnt;
					end
				end
				
			end	%'end' for the 'index' loop
			
		end
		
		%% Clean up preallocated arrays   (preallocation required for speed)
		for y=1:numel(index)
			
			cname=index(y).name;
			
			if isfield(ob.(cname),'nsamples')
				
				nsamples=ob.(cname).nsamples;
				%Remove any excess from preallocation of data
				if nsamples>0
					if numel(ob.(cname).data)>nsamples
						ob.(cname).data(nsamples+1:end)=[];
					end
					
					%Remove any excess from preallocation of properties
					proplist=fieldnames(ob.(cname));
					for isaac=1:numel(proplist)
						if isfield(ob.(cname).(proplist{isaac}),'cnt')
							cnt=ob.(cname).(proplist{isaac}).cnt;
							if numel(ob.(cname).(proplist{isaac}).value)>cnt
								ob.(cname).(proplist{isaac}).value(cnt+1:end)=[];
								ob.(cname).(proplist{isaac}).samples(cnt+1:end)=[];
								ob.(cname).(proplist{isaac})=rmfield(ob.(cname).(proplist{isaac}),'cnt');
							end
						end
					end
					
				end
			end
		end	%'end' for the 'groups/channels' loop
		
	end	%'end' for the 'Segment' loop
	
	fclose(fid);
	
	%% Assign the outputs
	ConvertedData(fnum).FileNameShort=FileNameShort;
	ConvertedData(fnum).FileFolder=FileFolder;
	ConvertedData(fnum).Data=postProcess(ob);
	
	Index(fnum).FileNameShort=FileNameShort;
	Index(fnum).FileFolder=FileFolder;
	Index(fnum).Data=index;
	
	%% Save the MAT file
	if SaveConvertedFile
		MATFileNameShort=sprintf('%s.mat',FileNameNoExt);
		MATFileNameLong=fullfile(FileFolder,MATFileNameShort);
		try
			save(MATFileNameLong,'ConvertedData','Index','ConvertVer')
			fprintf('\n\nConversion complete (saved in ''%s'').\n\n',MATFileNameShort)
		catch exception
			fprintf('\n\nConversion complete (could not save ''%s'').\n\t%s: %s\n\n',MATFileNameShort,exception.identifier,...
				exception.message)
		end
	else
		fprintf('\n\nConversion complete.\n\n')
	end
	
end	%'end' for the 'Number of Files' loop

end


function DataStructure=postProcess(ob)

	%Modified to return all information stored in the TDMS file to include name, start time, start time offset, samples
	%per read, total samples, unit description, and unit string.  Also provides event time and event description in
	%text form

	DataStructure.Root=[];
	DataStructure.MeasuredData.Name=[];
	DataStructure.MeasuredData.Data=[];
	DataStructure.Events.Name=[];
	DataStructure.Events.Data=[];
	
	varNameMask='';
	cntData=1;
	cntEvent=1;
	
	GroupNames=fieldnames(ob);

	for i=1:numel(GroupNames)
		cname=GroupNames{i};
		if strcmp(cname, 'Root')
			DataStructure.Root=ob.(cname);
		end
		if isfield(ob.(cname),'data')
			if strcmp(varNameMask,'Events')
				DataStructure.Events(cntEvent).Name=cname;

				if strcmp(DataStructure.Events(cntEvent).Name,'Description')
					event_string=char(ob.(cname).data');
					seperator=event_string(1:4);
					locations=findstr(seperator, event_string);
					num_events=max(size(locations));
					for j=1:num_events
						if j<num_events
							DataStructure.Events(cntEvent).Data(j,:)=cellstr(event_string(locations(j)+4:locations(j+1)-1));
						else
							DataStructure.Events(cntEvent).Data(j,:)=cellstr(event_string(locations(j)+4:max(size(event_string))));
						end
					end
				else
					DataStructure.Events(cntEvent).Data=ob.(cname).data;
				end
				cntEvent=cntEvent+1;

			else
				DataStructure.MeasuredData(cntData).Name=cname;
				DataStructure.MeasuredData(cntData).Data=ob.(cname).data;
				DataStructure.MeasuredData(cntData).Total_Samples=ob.(cname).nsamples;
				if isfield(ob.(cname),'wf_start_time')
					DataStructure.MeasuredData(cntData).Start_Time=ob.(cname).wf_start_time.value;
					DataStructure.MeasuredData(cntData).Start_Time_Offset=ob.(cname).wf_start_offset.value;
					DataStructure.MeasuredData(cntData).Sample_Rate=ob.(cname).wf_increment.value;
					DataStructure.MeasuredData(cntData).Samples_Per_Read=ob.(cname).wf_samples.value;
					DataStructure.MeasuredData(cntData).Units_Decription=char(ob.(cname).NI_UnitDescription.value)';
					DataStructure.MeasuredData(cntData).Unit_String=char(ob.(cname).unit_string.value)';
				end
				cntData = cntData + 1;
			end
		end

	end	%'end' for the 'groups/channels' loop

end


function  [FixedText,TruncFieldName,ValidFieldName]=fixcharformatlab(textin)
	%Private Function to remove all text that is not MATLAB variable name compatible
	
	textin=strrep(textin,'_0''/''','_0_');
	textin=strrep(textin,'''','');
	textin=strrep(textin,'\','');
	textin=strrep(textin,'/Untitled/','');
	textin=strrep(textin,'/','.');
	textin=strrep(textin,'-','');
	textin=strrep(textin,'?','');
	textin=strrep(textin,' ','_');
	textin=strrep(textin,'.','');
	textin=strrep(textin,'[','_');
	textin=strrep(textin,']','');
	textin=strrep(textin,'%','');
	textin=strrep(textin,'#','');
	textin=strrep(textin,'(','');
	textin=strrep(textin,')','');
	textin=strrep(textin,':','');
	textin=strrep(textin,'^','_');
	
	%Ensure that the name isn't too long
	maxid=namelengthmax;
	if numel(textin)<=maxid
		FixedText=textin;
		TruncFieldName=false;
	else
		FixedText=textin(1:maxid);
		TruncFieldName=true;
	end
	
	%Check for a valid fieldname
	ValidFieldName=isvarname(FixedText);
	if ~ValidFieldName
		%Check to see if maybe the issue is the first character is not a letter.  If it is, then add an 'a' to the front
		%of the string.
		if ~isletter(FixedText(1))
			if TruncFieldName || numel(FixedText)>=(maxid-1)
				FixedText=sprintf('a%s',FixedText(1:end-1));
			else
				FixedText=sprintf('a%s',FixedText);
			end
		end
	end
	%Confirm whether or not the issue has been fixed.
	ValidFieldName=isvarname(FixedText);
	
end


function matType=LV2MatlabDataType(LVType)
%Cross Refernce Labview TDMS Data type to MATLAB

	switch LVType
		case 0   %tdsTypeVoid
			matType='';
		case 1   %tdsTypeI8
			matType='int8';
		case 2   %tdsTypeI16
			matType='int32';
		case 3   %tdsTypeI32
			matType='int32';
		case 4   %tdsTypeI64
			matType='int64';
		case 5   %tdsTypeU8
			matType='uint8';
		case 6   %tdsTypeU16
			matType='uint16';
		case 7   %tdsTypeU32
			matType='uint32';
		case 8   %tdsTypeU64
			matType='uint64';
		case 9  %tdsTypeSingleFloat
			matType='float32';
		case 10  %tdsTypeDoubleFloat
			matType='float64';
		case 11  %tdsTypeExtendedFloat
			matType='';
		case 32  %tdsTypeString
			matType='uint8=>char';
		case 33  %tdsTypeBoolean
			matType='bit1';
		case 68  %tdsTypeTimeStamp
			matType='bit224';
		otherwise
			matType='Undefined';
	end

end

