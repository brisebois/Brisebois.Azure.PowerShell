Add-Type @'
    using System;
    public class OAuthContext{
        public string AccessToken{get;set;}
        public string TokenType{get;set;}
        public string ExpiresIn{get;set;}
        public string RefreshToken{get;set;}
    }
'@

function Get-ApiToken([string]$methodUrl, [string]$username,[string] $password,[string] $authorization, [string] $subscriptionkey)
{
  $methodtype = 'POST'
  $contentType = 'application/x-www-form-urlencoded'
 
  $dict = @{}
  $dict.Add('Authorization',$authorization)
 
  $methodURL = $methodURL+'?subscription-key='+$subscriptionkey
 
  $body = [System.Text.Encoding]::UTF8.GetBytes('grant_type=password&username='+$username+'&password='+$password) 
 
  $response = Invoke-RestMethod -Method $methodtype -Uri $methodUrl -Headers $dict -ContentType $contentType -Body $body
 
  $context = New-Object OAuthContext
 
  $context.AccessToken = $response.access_token
  $context.ExpiresIn = $response.expires_in
  $context.RefreshToken = $response.refresh_token
  $context.TokenType = $response.token_type
 
  return $context
}

function Get-ApiResource([string]$methodurl,[OAuthContext]$oauthContext,[string]$subscriptionkey)
{
    $headers = @{}
    $headers.Add('Authorization',$oauthContext.TokenType + ' ' + $oauthContext.AccessToken)
 
    $methodtype = 'GET'
    $methodurl = $methodurl+'?subscription-key='+$subscriptionkey
 
    return Invoke-RestMethod -Method $methodtype -Uri $methodurl -Headers $headers
}