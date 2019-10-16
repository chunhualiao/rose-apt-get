import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-extra', nargs="+", type=str)
    args = parser.parse_args()

    files    = {}
    
    #Load File Names
    coreFile = open('rose.find', 'r')
    for line in coreFile:
        files[line[2:].strip()] = 'rose'
    coreFile.close()

    allFile = open('rose-tools.find', 'r')
    for line in allFile:
        fileName = line[2:].strip()
        if not fileName in files:
            files[fileName] = 'rose-tools'
    allFile.close()
    
    if args.extra == None: args.extra = []
    for toolName in args.extra:
        toolFile = open(toolName + '.find', 'r')
        for line in toolFile:
            fileName = line[2:].strip()
            if not fileName in files or files[fileName] == 'rose-tools':
                files[fileName] = toolName
        toolFile.close()

    #Load Bin Lists
    bins = {}
    coreFile = open('rose.bin', 'r')
    roseBin = []
    for line in coreFile:
        roseBin.append(line.strip())
    bins['rose'] = roseBin
    coreFile.close()

    toolsFile = open('rose-tools.bin', 'r')
    toolsBin = []
    for line in toolsFile:
        tool = line.strip()
        if not tool in roseBin:
            toolsBin.append(tool)
    bins['rose-tools'] = toolsBin
    toolsFile.close()
    
    allToolsBin = []
    for toolName in args.extra:
        toolFile = open(toolName + '.bin', 'r') 
        toolBin = []
        for line in toolFile:
            tool = line.strip()
            if not ((tool in roseBin) or (tool in allToolsBin)):
                toolBin.append(tool)
                allToolsBin.append(tool)
        bins[toolName] = toolBin
        toolFile.close()

    #Build File List
    fileLists = {'rose':[], 'rose-tools':[]}
    for tool in args.extra:
        fileLists[tool] = []

    for fileName in files.keys():
        fileName = str(fileName)
        if not (files[fileName] == 'rose' or files[fileName] == 'rose-tools'):
            fileLists[files['rose-tools']].append(fileName)            
        fileLists[files[fileName]].append(fileName)
           
    for tool in fileLists.keys():
        fileLists[tool].sort() 

        installFile = open(tool + '.install', 'w')
        for name in fileLists[tool]:
            sourceFileName = 'usr/rose/' + name
            destFileName = '/' + '/'.join(sourceFileName.split('/')[:-1])
            installFile.write(sourceFileName + ' ' + destFileName + '\n')
        for binFile in bins[tool]: 
            installFile.write('usr/bin/' + binFile + ' /usr/bin/' +  '\n')
