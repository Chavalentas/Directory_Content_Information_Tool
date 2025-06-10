param (
    [Parameter(Mandatory=$true)]
    [string]$fromFilePath,
    [Parameter(Mandatory=$true)]
    [string]$toFilePath,
    [Parameter(Mandatory=$true)]
    [int]$depth  
)

function getTextFileContent{
    param(
        [Parameter(Mandatory)]
        [string]$filePath
    )

    if (-not ([System.IO.File]::Exists($filePath))){
        throw "File does not exist!"
    }

    $extn = [IO.Path]::GetExtension($filePath)

    if (-not ($extn -eq ".txt")){
        throw "Wrong file extension detected!"
    }


    return Get-Content -Path $filePath
}

function removeElementAtIndex{
    param(
        [Parameter(Mandatory)]
        [string]$inputString,
        [Parameter(Mandatory)]
        [int]$index
    )

    $inputLength = $inputString.Length

    if ($inputLength -eq 0){
        return $inputString
    }

    if (-not(($index -ge 0) -and ($index -le ($inputLength - 1)))){
        throw "Index out of range!"
    }

    $result = ""

    for ($i = 0; $i -lt $inputLength; $i++){
        if ($i -ne $index){
           $result = $result + $inputString[$i]
        }
    }

    return $result
}

function removeElementInArrayAtIndex{
    param(
        [Parameter(Mandatory)]
        [string[]]$inputArray,
        [Parameter(Mandatory)]
        [int]$index
    )

    $inputLength = $inputArray.Length

    if ($inputLength -eq 0){
        return $inputArray
    }

    if (-not(($index -ge 0) -and ($index -le ($inputLength - 1)))){
        throw "Index out of range!"
    }

    $result = @()

    for ($i = 0; $i -lt $inputLength; $i++){
        if ($i -ne $index){
           $result = $result + $inputArray[$i]
        }
    }

    return $result
}

function appendElements{
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$inputStringArray,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$elementsToAppend
    )

    $result = $inputStringArray

    if ($null -eq $elementsToAppend){
        return $result
    }

    $inputLength = $elementsToAppend.Length

    for ($i = 0; $i -lt $inputLength; $i++){
        if ($i -ne $index){
           $result = $result + $elementsToAppend[$i]
        }
    }

    return $result
}

function isValidFile{
    param(
        [Parameter(Mandatory)]
        [string]$filePath
    ) 

    if (-not ([System.IO.File]::Exists($filePath))){
        return $false
    }

    if (-not ((Get-Item $filePath) -is [System.IO.FileInfo])){
        return $false
    }

    return $true
}

function isValidDirectory{
    param(
        [Parameter(Mandatory)]
        [string]$directoryPath
    ) 

    if (-not ([System.IO.Directory]::Exists($directoryPath))){
        return $false
    }

    if (-not ((Get-Item $directoryPath) -is [System.IO.DirectoryInfo])){
        return $false
    }

    return $true
}

function getAbsoluteValue{
    param(
        [Parameter(Mandatory)]
        [int]$inputValue
    )
    
    if ($inputValue -lt 0){
        return $inputValue * -1
    }

    return $inputValue
}

function createFileIfNotExists{
    param(
        [Parameter(Mandatory)]
        [string]$filePath
    )

    if (-not ([System.IO.File]::Exists($filePath))){
        New-Item -ItemType "file" -Path $filePath
    }
}

function getFilesInDirectory{
    param(
        [Parameter(Mandatory)]
        [string]$directoryPath
    )

    if (-not ([System.IO.Directory]::Exists($directoryPath))){
        throw "The directory does not exist!"
    }

    if (-not (isValidDirectory($directoryPath))){
        throw "No directory!"
    }

    $prefix = $directoryPath

    if ($prefix[$prefix.Length - 1] -eq '\'){
        $prefix = removeElementAtIndex $prefix ($prefix.Length - 1)
    }

    $children = Get-ChildItem -Path $directoryPath -Name
    $result = @()

    foreach ($child in $children){
        $filePath = $prefix + "\" + $child
        if (isValidFile($filePath)){
            $result += $filePath
        }
    }

    return $result
}

function getDirectoriesInDirectory{
    param(
        [Parameter(Mandatory)]
        [string]$directoryPath
    )

    if (-not ([System.IO.Directory]::Exists($directoryPath))){
        throw "The directory does not exist!"
    }

    if (-not (isValidDirectory($directoryPath))){
        throw "No directory!"
    }

    $prefix = $directoryPath

    if ($prefix[$prefix.Length - 1] -eq '\'){
        $prefix = removeElementAtIndex $prefix ($prefix.Length - 1)
    }

    $children = Get-ChildItem -Path $directoryPath -Name
    $result = @()

    foreach ($child in $children){
        $dirPath = $prefix + "\" + $child
        if (isValidDirectory($dirPath)){
            $result += $dirPath
        }
    }

    return $result
}

function getContentOfDirectory{
    param(
        [Parameter(Mandatory)]
        [string]$directoryPath,
        [Parameter(Mandatory)]
        [int]$depth,
        [Parameter(Mandatory)]
        [ref][string[]]$acc
    )   

    if (-not (isValidDirectory($directoryPath))){
        throw "No directory!"
    }
    
    if ($depth -le 0){
        throw "Depth has to be greater than 0!"
    }

    $directories = getDirectoriesInDirectory $directoryPath
    $files = getFilesInDirectory $directoryPath

    if ($depth -eq 1){
        if ($null -ne $files){
            $acc = appendElements $acc $files
        }

        if ($null -ne $directories){
            $acc = appendElements $acc $directories
        }

        return $acc.Value
    }

    if ($null -ne $files){
        $acc = appendElements $acc $files
    }

    foreach ($directory in $directories){
        if ($null -ne $directory){
            $acc = appendElements $acc @($directory)
            $dirContent = getContentOfDirectory $directory ($depth - 1) ([ref]$acc)
    
            if ($null -ne $dirContent){
                $dirContent = removeElementInArrayAtIndex $dirContent 0
                $acc = appendElements $acc $dirContent
            }
        }
    }

    return $acc.Value
}

if (-not ([System.IO.File]::Exists($fromFilePath))){
    throw "The from file path does not exist!"
}

if (-not (isValidFile($fromFilePath))){
    throw "The from file path is not valid file!"
}

$extn = [IO.Path]::GetExtension($fromFilePath)

if (-not ($extn -eq ".txt")){
    throw "Wrong file extension of the from file detected!"
}

if (-not ($toFilePath.Length -ge 1)){
    throw "Invalid file length!"
}

if (-not ([System.IO.File]::Exists($toFilePath))){
    New-Item -ItemType File -Name $toFilePath
}

$toExtn = [IO.Path]::GetExtension($toFilePath)

if (-not ($toExtn -eq ".txt")){
    throw "Wrong file extension of the to file detected!"
}

if (-not ($depth -ge 1)){
    throw "Depth value has to be greater or equal to 1!"
}

$result = @()

$fromContent = Get-Content -Path $fromFilePath

foreach ($el in $fromContent){
    [string[]]$inputArray = @()
    $cont = getContentOfDirectory $el $depth ([ref]($inputArray))
    $result = $result + $cont
}

$toContent = Get-Content -Path $toFilePath 

if ($null -ne $toContent){
  (appendElements $toContent $result) | Out-File -FilePath $toFilePath 
} else{
   $result | Out-File -FilePath $toFilePath 
}