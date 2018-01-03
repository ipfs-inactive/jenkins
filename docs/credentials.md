Jenkins in production and beta environment requires two credentials which are applied at deploy-time

Current flow for

- config.xml production edition
  - turns of the master from doing any jobs
  - applies the authorizationStrategy to be Github instead of local
  - contains `clientID` and `clientSecret` that must be hidden
- credentials.xml
  - contains github credentials for authenticating ImmutableJenkins
    - used for setting commit status and scanning repositories
- worker-sshkey
  - used to authenticate the worker

## Future

Instead, it would be much simpler if we didn't use files as credentials (or git patches for that part) and instead used environment variables that would be applied when starting jenkins or deploying.

## Decrypting/Encrypting

```
def secret = hudson.util.Secret.fromString("zlvnUMF1/hXwe3PLoitMpQ6BuQHBJ1FnpH7vmMmQ2qk=")
println(secret.getPlainText())

def secret = hudson.util.Secret.fromString("your password")
println(secret.getEncryptedValue())
```

From: https://github.com/jenkinsci/jenkins/blob/30ab4481f286a5c33499489dfcb9b3df6587ff38/core/src/main/java/hudson/util/Secret.java

## On init

On initialization (startup) of jenkins, it tries to set new values for a couple
of things if those values haven't been initialized since before.

Script for setting Github credentials

```
import hudson.security.SecurityRealm
import org.jenkinsci.plugins.GithubSecurityRealm

String githubWebUri = 'https://github.com'
String githubApiUri = 'https://api.github.com'
String oauthScopes = 'read:org,user:email'

String clientIDPath = '/tmp/clientid'
String clientSecretPath = '/tmp/clientsecret'

try {
	assert new File(clientIDPath) : "Client ID not found"
	assert new File(clientSecretPath) : "Client Secret not found"

	String clientID = new File(clientIDPath).text
	String clientSecret = new File(clientSecretPath).text

	assert new File(clientIDPath).delete() : "Could not delete Client ID"
	assert new File(clientSecretPath).delete() : "Could not delete Client Secret"


	SecurityRealm github_realm = new GithubSecurityRealm(
		githubWebUri, githubApiUri, clientID, clientSecret, oauthScopes
	)

	//check for equality, no need to modify the runtime if no settings changed
	if(!github_realm.equals(Jenkins.instance.getSecurityRealm())) {
			Jenkins.instance.setSecurityRealm(github_realm)
			Jenkins.instance.save()
	}
} catch(Exception err) {
	println(err)
	println("Tried setting new secrets but either already done and we couldnt")
}
```

Script for setting ImmutableJenkins auth token (updates password for ID `immutablejenkins`)

```
import com.cloudbees.plugins.credentials.impl.*;
import com.cloudbees.plugins.credentials.*;
import com.cloudbees.plugins.credentials.domains.*;
Credentials c = (Credentials) new UsernamePasswordCredentialsImpl(
	CredentialsScope.GLOBAL,
	'immutablejenkins',
	'ImmutableJenkins Github login with auth token',
	'immutablejenkins',
	'authtoken_replace_me'
)
assert SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), c) : "Could not add ImmutableJenkins credentials"
```

Script for setting the GH Webhook Secret

```
import hudson.util.Secret
import com.cloudbees.plugins.credentials.impl.*;
import com.cloudbees.plugins.credentials.*;
import com.cloudbees.plugins.credentials.domains.*;
import org.jenkinsci.plugins.plaincredentials.impl.*;

def secretPlaintext = "secretvalue"
def secret = Secret.fromString(secretPlaintext)

Credentials c = (Credentials) new StringCredentialsImpl(
	CredentialsScope.GLOBAL,
	'github-webhook-secret',
	'Secret for accepting Github Webhooks',
	secret,
)
assert SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), c) : "Could not add secret for Github Webhook"
```

## Can't create users on boot...

When starting jenkins with Github auth, only admins defined via the list are
admins which means whatever user ("anonomous") that runs the `init.groovy.d`
script will be failing as it doesn't have the right credentials yet

```
def user = User.get('victorbjelkholm')
hudson.security.ACL.as(user)
User.current()
```
