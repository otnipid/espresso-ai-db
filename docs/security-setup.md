# Security Setup Guide

This document outlines the required GitHub secrets and security configurations for the Espresso ML infrastructure.

## 🔐 Required GitHub Secrets

### **CI/CD Test Secrets**
These secrets are used for testing in GitHub Actions workflows:

```bash
# CI Testing Credentials
CI_TEST_PASSWORD=your-secure-test-password
CI_TEST_USER=testuser
CI_TEST_DB=testdb
```

### **Production Secrets**
These secrets are used for production deployments:

```bash
# Production Database Credentials
POSTGRES_PASSWORD_PROD=your-secure-prod-password
POSTGRES_USER_PROD=espresso_prod_user
POSTGRES_DB_PROD=espresso_ml_production

# Kubernetes Configuration
KUBE_CONFIG_PROD=your-kubeconfig-base64-encoded
```

### **Development Secrets**
These secrets are used for development deployments:

```bash
# Development Database Credentials
POSTGRES_PASSWORD_DEVELOPMENT=your-secure-dev-password
POSTGRES_USER_DEVELOPMENT=espresso_dev_user
POSTGRES_DB_DEVELOPMENT=espresso_ml_development

# Kubernetes Configuration
KUBE_CONFIG_DEVELOPMENT=your-kubeconfig-base64-encoded
```

### **Security Scanning Secrets**
These secrets are used for security scanning tools:

```bash
# Semgrep
SEMGREP_APP_TOKEN=your-semgrep-token

# GitHub Token (automatically provided)
GITHUB_TOKEN=automatically-provided-by-github-actions
```

## 🚀 Setting Up GitHub Secrets

### **1. Navigate to Repository Settings**
1. Go to your GitHub repository
2. Click on **Settings** tab
3. Click on **Secrets and variables** → **Actions**
4. Click **New repository secret**

### **2. Add Required Secrets**

#### **CI Test Secrets**
```
Name: CI_TEST_PASSWORD
Value: [Generate a strong password, e.g., openssl rand -base64 32]

Name: CI_TEST_USER  
Value: testuser

Name: CI_TEST_DB
Value: testdb
```

#### **Production Secrets**
```
Name: POSTGRES_PASSWORD_PROD
Value: [Generate a strong password, e.g., openssl rand -base64 32]

Name: POSTGRES_USER_PROD
Value: espresso_prod_user

Name: POSTGRES_DB_PROD
Value: espresso_ml_production

Name: KUBE_CONFIG_PROD
Value: [Base64 encoded kubeconfig file]
```

#### **Development Secrets**
```
Name: POSTGRES_PASSWORD_DEVELOPMENT
Value: [Generate a strong password, e.g., openssl rand -base64 32]

Name: POSTGRES_USER_DEVELOPMENT
Value: espresso_dev_user

Name: POSTGRES_DB_DEVELOPMENT
Value: espresso_ml_development

Name: KUBE_CONFIG_DEVELOPMENT
Value: [Base64 encoded kubeconfig file]
```

#### **Security Scanning Secrets**
```
Name: SEMGREP_APP_TOKEN
Value: [Get from Semgrep dashboard]

# GITHUB_TOKEN is automatically provided by GitHub Actions
```

## 🔧 Generating Secure Passwords

### **Using OpenSSL**
```bash
# Generate 32-character secure password
openssl rand -base64 32

# Generate 16-character alphanumeric password
openssl rand -hex 16
```

### **Using Python**
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

### **Using pwgen**
```bash
# Install pwgen: brew install pwgen or apt-get install pwgen
pwgen -s 32 1
```

## 📋 Kubernetes Configuration Setup

### **1. Get Your Kubeconfig**
```bash
# For local clusters (kind, minikube)
kubectl config view --raw > kubeconfig

# For cloud providers, follow their documentation
```

### **2. Encode for GitHub Secrets**
```bash
# Encode kubeconfig file
base64 -i kubeconfig | tr -d '\n'

# Copy the output and paste as the secret value
```

### **3. Test the Configuration**
```bash
# Decode and test locally
echo "BASE64_ENCODED_CONFIG" | base64 -d > test-kubeconfig
export KUBECONFIG=test-kubeconfig
kubectl get nodes
```

## 🛡️ Security Best Practices

### **1. Password Requirements**
- Minimum 16 characters
- Include uppercase, lowercase, numbers, and special characters
- Use unique passwords for each environment
- Rotate passwords regularly

### **2. Access Control**
- Limit who can access production secrets
- Use different credentials for each environment
- Implement least privilege principle
- Regularly audit access permissions

### **3. Secret Management**
- Never commit secrets to version control
- Use GitHub's encrypted secrets
- Consider using a secret management service for production
- Monitor secret usage and access logs

### **4. Environment Isolation**
- Use separate databases for each environment
- Different credentials for dev/staging/prod
- Network segmentation between environments
- Regular security audits

## 🔍 Security Validation

### **1. Verify Secrets Are Working**
```bash
# Test CI workflow locally
act -j schema-validation

# Check that secrets are properly referenced
grep -r "secrets\." .github/workflows/
```

### **2. Validate No Hardcoded Credentials**
```bash
# Scan for hardcoded passwords
grep -r -i "password\|secret\|token" --exclude-dir=.git .

# Check for example credentials in documentation
grep -r "password_123\|testpass\|yourpassword" docs/
```

### **3. Run Security Scans**
```bash
# Run Gitleaks to detect secrets
gitleaks detect --source . --verbose

# Run Semgrep for security issues
semgrep --config=auto .
```

## 🚨 Common Security Issues

### **1. Hardcoded Credentials**
❌ **Wrong:**
```yaml
password: testpass
POSTGRES_PASSWORD=dev_password_123
```

✅ **Correct:**
```yaml
password: ${{ secrets.CI_TEST_PASSWORD }}
POSTGRES_PASSWORD=${{ secrets.POSTGRES_PASSWORD_DEVELOPMENT }}
```

### **2. Documentation Examples**
❌ **Wrong:**
```bash
POSTGRES_PASSWORD=dev_password_123
```

✅ **Correct:**
```bash
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-your_secure_password}
```

### **3. Default Passwords**
❌ **Wrong:**
```yaml
password: admin
password: password123
```

✅ **Correct:**
```yaml
password: null  # Force override with secrets
```

## 📞 Security Incident Response

### **1. If Secrets Are Exposed**
1. Immediately rotate all exposed secrets
2. Revoke any compromised access tokens
3. Audit all recent activity
4. Update documentation and examples
5. Notify security team

### **2. Secret Rotation Schedule**
- **CI/CD secrets**: Every 90 days
- **Production secrets**: Every 30 days
- **Development secrets**: Every 60 days
- **API tokens**: Every 60 days

### **3. Monitoring and Alerts**
- Set up alerts for secret usage
- Monitor failed authentication attempts
- Track secret access patterns
- Regular security scans

## 🔄 Maintenance

### **1. Regular Tasks**
- [ ] Monthly secret rotation
- [ ] Quarterly security audits
- [ ] Update documentation
- [ ] Review access permissions
- [ ] Test backup and restore procedures

### **2. Security Checklist**
- [ ] No hardcoded credentials in code
- [ ] All passwords use GitHub secrets
- [ ] Different credentials per environment
- [ ] Latest security patches applied
- [ ] Security scanning enabled
- [ ] Access logs monitored

## 📚 Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Semgrep Security Scanning](https://semgrep.dev/docs/)
- [Gitleaks Secret Detection](https://github.com/zricethezav/gitleaks)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)

---

⚠️ **Important**: Never share or commit secrets to version control. Always use GitHub's encrypted secrets for sensitive information.
