function Add-Version
{
  param
  (
    [System.String]
    $url
  )
  
  $version ='2014-02-14'
  
  return $($url+'?api-version='+$version)
}

function Invoke-ApiManagementResource
{
  param
  (
    [System.String]
    $MethodUrl,
    
    [System.String]
    $Authorization,
    
    [System.String]
    $Body,
    
    [System.String]
    $ContentType
    
  )
  
  $dict = @{}
  $dict.Add('Authorization',$authorization)
  
  $response = Invoke-RestMethod -Method 'POST' -Uri $(Add-Version -url $MethodUrl) -Headers $dict -ContentType $ContentType -Body $body
  
  return $response
}

function Remove-ApiManagementResource
{
  param
  (
    [System.String]
    $MethodUrl,
    
    [System.String]
    $Authorization,
    
    [System.String]
    $Body,
    
    [System.String]
    $ETag,
    
    [System.String]
    $ContentType
    
  )
  
  $dict = @{}
  $dict.Add('Authorization',$authorization)
  $dict.Add('If-Match',$ETag)
  
  $response = Invoke-RestMethod -Method 'DELETE' -Uri $(Add-Version -url $MethodUrl) -Headers $dict -ContentType $ContentType  
  return $response
}

function Update-ApiManagementResource
{
  param
  (
    [System.String]
    $MethodUrl,
    
    [System.String]
    $Authorization,
    
    [System.String]
    $Body,
    
    [System.String]
    $ContentType
    
  )
  
  $dict = @{}
  $dict.Add('Authorization',$authorization)
  
  $response = Invoke-RestMethod -Method 'PUT' -Uri $(Add-Version -url $MethodUrl) -Headers $dict -ContentType $ContentType -Body $body
  
  return $response
}

function Get-ApiManagementResourceMetadata
{
  param
  (
    [System.String]
    $MethodUrl,
    
    [System.String]
    $Authorization,
    
    [System.String]
    $ContentType
    
  )
  
  $dict = @{}
  $dict.Add('Authorization',$authorization)
  
  $response = Invoke-WebRequest -Method 'HEAD' -Uri $(Add-Version -url $MethodUrl) -Headers $dict -ContentType $ContentType
  
  return $response
}

function Get-ApiManagementResource
{
  param
  (
    [System.String]
    $MethodUrl,
    
    [System.String]
    $Authorization,
    
    [System.String]
    $ContentType
    
  )
  
  $dict = @{}
  $dict.Add('Authorization',$authorization)
  
  $response = Invoke-RestMethod -Method 'GET' -Uri $(Add-Version -url $MethodUrl) -Headers $dict -ContentType $ContentType
  
  return $response
}

function Get-Products
{
    return Get-ApiManagementResource -MethodUrl $($serviceUrl+'/products') -Authorization $authorizatoin -ContentType $contentType
}

function Get-Product
{
   param
   (
     [System.String]
     $id
   )

    return Get-ApiManagementResource -MethodUrl $($serviceUrl+''+$id) -Authorization $authorizatoin -ContentType $contentType
}

function Get-Api
{
   param
   (
     [System.String]
     $id
   )

    return Get-ApiManagementResource -MethodUrl $($serviceUrl+''+$id) -Authorization $authorizatoin -ContentType $contentType
}

function Get-ProductApiList
{
   param
   (
     [System.String]
     $id
   )

    return Get-ApiManagementResource -MethodUrl $($serviceUrl+''+$id+'/apis') -Authorization $authorizatoin -ContentType $contentType
}

function Get-ProductMetadata
{
   param
   (
     [System.String]
     $id
   )

    $response = Get-ApiManagementResourceMetadata -MethodUrl $($serviceUrl+''+$id) -Authorization $authorizatoin -ContentType $contentType

    return $response.Headers.'ETag'
}

function Get-Users
{
    return Get-ApiManagementResource -MethodUrl $($serviceUrl+'/users') -Authorization $authorizatoin -ContentType $contentType
}

function Get-User
{
   param
   (
     [System.String]
     $id
   )

    return Get-ApiManagementResource -MethodUrl $($serviceUrl+''+$id) -Authorization $authorizatoin -ContentType $contentType
}

function Get-UserMetadata
{
   param
   (
     [System.String]
     $id
   )

    $response = Get-ApiManagementResourceMetadata -MethodUrl $($serviceUrl+''+$id) -Authorization $authorizatoin -ContentType $contentType

    return $response.Headers.'ETag'
}

function Remove-User
{
   param
   (
     [System.String]
     $id
   )

    $etag = Get-UserMetadata  -id $id
    return Remove-ApiManagementResource -MethodUrl $($serviceUrl+''+$id) -Authorization $authorizatoin -ContentType $contentType -ETag $etag
}

function Add-User
{
   param
   (
     [System.String]
     $ID,
     
     [System.String]
     $FirstName,
     
     [System.String]
     $LastName,

     [System.String]
     $Email,

     [System.String]
     $Password,

     [System.String]
     [ValidateSet('active','blocked')]
     $State,

     [System.String]
     $Note = ''
   )
    
    $body = @{}
    $body.Add('firstName',$FirstName)
    $body.Add('lastName',$LastName)
    $body.Add('email',$Email)
    $body.Add('note',$Note)
    $body.Add('password',$Password)
    $body.Add('state',$State)
                        
    return Update-ApiManagementResource -MethodUrl $($serviceUrl+'/users/'+$ID) -Authorization $authorizatoin -Body $(ConvertTo-Json $body) -ContentType $contentType
}

function Get-UserGroupList
{
   param
   (
     [System.String]
     $id
   )

    return Get-ApiManagementResource -MethodUrl $($serviceUrl+''+$id+'/groups') -Authorization $authorizatoin -ContentType $contentType
}

function Get-UserSubscriptionList
{
   param
   (
     [System.String]
     $id
   )

    return Get-ApiManagementResource -MethodUrl $($serviceUrl+''+$id+'/subscriptions') -Authorization $authorizatoin -ContentType $contentType
}

function Get-Groups
{
    return Get-ApiManagementResource -MethodUrl $($serviceUrl+'/groups') -Authorization $authorizatoin -ContentType $contentType
}

function Get-Group
{
   param
   (
     [System.String]
     $id
   )

    return Get-ApiManagementResource -MethodUrl $($serviceUrl+''+$id) -Authorization $authorizatoin -ContentType $contentType
}

function Get-GroupUsers
{
   param
   (
     [System.String]
     $id
   )

    return Get-ApiManagementResource -MethodUrl $($serviceUrl+''+$id+'/users') -Authorization $authorizatoin -ContentType $contentType
}

function Get-Subscriptions
{
    return Get-ApiManagementResource -MethodUrl $($serviceUrl+'/subscriptions') -Authorization $authorizatoin -ContentType $contentType
}

Set-Variable -Name contentType -Value 'application/json'

Export-ModuleMember 'Add-Version'
Export-ModuleMember 'Get-ApiManagementResource'
Export-ModuleMember 'Get-ApiManagementResourceMetadata'
Export-ModuleMember 'Remove-ApiManagementResource'
Export-ModuleMember 'Update-ApiManagementResource'
Export-ModuleMember 'Invoke-ApiManagementResource'
Export-ModuleMember 'Get-Subscriptions'
Export-ModuleMember 'Add-User'
Export-ModuleMember 'Remove-User'
Export-ModuleMember 'Get-Users'
Export-ModuleMember 'Get-User'
Export-ModuleMember 'Get-UserGroupList'
Export-ModuleMember 'Get-UserSubscriptionList'
Export-ModuleMember 'Get-Products'
Export-ModuleMember 'Get-Product'
Export-ModuleMember 'Get-ProductMetadata'
Export-ModuleMember 'Get-ProductApiList'
Export-ModuleMember 'Get-Groups'
Export-ModuleMember 'Get-Group'
Export-ModuleMember 'Get-GroupUsers'
Export-ModuleMember 'Get-Api'