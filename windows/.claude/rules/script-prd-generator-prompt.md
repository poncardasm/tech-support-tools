# PowerShell Script PRD Generator Prompt

When I request a PowerShell script (e.g., "build me a Disk Analyzer script" or "create a Network Diagnostics tool"), you must FIRST ask clarifying questions to understand my requirements, THEN create a comprehensive Product Requirements Document (PRD) before writing any code.

## Your Two-Step Process

### STEP 1: Ask Clarifying Questions (REQUIRED)

Before creating the PRD, you MUST ask relevant questions to understand:

**Scope & Purpose:**

- What specific problem are you trying to solve?
- Who will use this script? (You personally, your team, general IT support?)
- What's the primary use case scenario?

**Functionality:**

- Should this work on local machine only or support remote computers?
- Do you want interactive prompts or command-line parameters only?
- What specific information/metrics do you need from this tool?
- Are there any specific features you definitely want/don't want?

**Technical Requirements:**

- Does this need to run with administrator privileges?
- Any specific Windows versions to support?
- Should it work with any particular existing tools/systems?

**Output & Reporting:**

- What output format would be most useful? (Console objects, CSV, HTML report, JSON?)
- Do you need the ability to export results?
- Should it include visualizations or just data?

**Safety & Security:**

- Will this make any changes to the system (or just read/report)?
- If it makes changes, what safety mechanisms do you want? (WhatIf, Confirm, backups?)
- Any specific security concerns?

**Additional Context:**

- Is there a similar tool/script you've seen that you like?
- Any specific constraints? (performance, dependencies, complexity)
- Timeline/priority? (quick and simple vs. feature-rich)

### STEP 2: Create the PRD

Only after receiving answers, create the PRD following this structure:

## PRD Structure You Must Follow

### 1. Project Overview

- **Script Name**: Official name following Verb-Noun convention
- **Version**: Starting version (1.0.0)
- **Purpose**: Clear problem statement - what user pain point does this solve?
- **Target Users**: IT support specialists, system administrators, etc.
- **Use Cases**: 3-5 real-world scenarios where this script would be used

### 2. Functional Requirements

- **Core Features**: List all primary functions the script must perform
- **Input Requirements**: What parameters/inputs does the script accept?
- **Output Requirements**: What data does the script return? Format?
- **Success Criteria**: How do we know the script works correctly?

### 3. Technical Specifications

- **PowerShell Version**: Minimum version required
- **Required Modules**: Any dependencies
- **Permissions Required**: Administrator / Standard User
- **Platform Support**: Windows 10, 11, Server versions
- **Performance Targets**: Expected runtime, resource usage limits

### 4. Parameters Definition

For each parameter, specify:

- Name and type
- Mandatory or optional
- Default value (if applicable)
- Validation rules
- Description and purpose

### 5. Security & Safety Requirements

- **Security Considerations**: Authentication, credential handling, data protection
- **Safety Mechanisms**: `-WhatIf`, `-Confirm`, backups needed?
- **Risk Assessment**: What could go wrong? What are the safeguards?
- **Logging Requirements**: What should be logged for audit/troubleshooting?

### 6. Error Handling Strategy

- **Expected Errors**: List potential error scenarios
- **Error Messages**: How should errors be communicated?
- **Fallback Behavior**: What happens when operations fail?
- **Recovery Procedures**: Can operations be rolled back?

### 7. Output & Reporting

- **Primary Output**: Object structure and properties
- **Export Options**: CSV, JSON, HTML report?
- **Verbosity Levels**: What info at Verbose/Debug levels?
- **Progress Indication**: For long-running operations

### 8. Testing Requirements

- **Test Scenarios**: List specific test cases
- **Test Environment**: VM specs, OS versions to test
- **Edge Cases**: What unusual scenarios must be tested?
- **Acceptance Criteria**: Conditions for script to be considered complete

### 9. Documentation Requirements

- **Help Documentation**: Synopsis, description, examples needed
- **README Content**: What must be in the README.md?
- **Code Comments**: Areas requiring detailed inline comments
- **Usage Examples**: Minimum 3 practical examples

### 10. Future Enhancements (Optional)

- **V1.0 Scope**: What's included in first release
- **Future Features**: Ideas for v1.1, v2.0
- **Known Limitations**: What the script won't do

## Complete Workflow Example

### When I say: "Build me a Disk Analyzer script"

**Your response should be:**

I'll help you create a Disk Analyzer script. Let me ask some clarifying questions first to ensure the PRD meets your needs:

**Scope & Purpose:**

1. What specific disk analysis problem are you trying to solve? (Finding large files? Checking free space? Identifying space hogs?)
2. Will you use this for personal troubleshooting or professional IT support work?

**Functionality:** 3. Should this analyze local disks only, or also support remote computers? 4. Do you want to find largest files/folders, or focus on space usage by drive/partition? 5. Any specific file types or folders you want to include/exclude?

**Technical Requirements:** 6. Should this require administrator privileges or work with standard user permissions?

**Output & Reporting:** 7. What output format would be most useful? (Console table, CSV export, HTML report with charts?) 8. Do you want visual indicators (like progress bars) for large disk scans?

**Performance:** 9. Should there be limits on scan depth or file count to prevent long-running operations?

**Additional Context:** 10. Have you seen similar tools you like? What features did they have? 11. Is this for your portfolio, so you want it feature-rich, or quick and practical?

Please answer whichever questions are relevant, and I'll create a detailed PRD based on your needs.

### After receiving your answers:

Based on your requirements, here's the PRD:

```md
# PRD: Get-DiskSpaceAnalyzer

## 1. Project Overview

**Script Name**: Get-DiskSpaceAnalyzer
**Version**: 1.0.0
**Purpose**: [Based on your answers]

[Complete all 10 sections based on your specific requirements]
```

Does this PRD meet your requirements? Would you like me to:

- Add/remove any features?
- Adjust the scope?
- Modify any technical specifications?

Once you approve, I'll generate the script following these requirements and the powershell-standards.md guidelines.

## Important Rules

- ✅ **ALWAYS ask clarifying questions first** - never skip to PRD creation
- ✅ Ask 5-10 targeted questions relevant to the script type
- ✅ Listen to the answers and incorporate them into the PRD
- ✅ If answers are still vague, ask follow-up questions
- ✅ Be specific in PRD requirements - avoid vague descriptions
- ✅ Consider security and safety in every PRD
- ✅ Make PRD realistic for a portfolio project (not enterprise-scale)
- ✅ Reference `powershell-standards.md` standards
- ❌ Don't skip clarifying questions
- ❌ Don't make assumptions without asking
- ❌ Don't write code until PRD is approved
- ❌ Don't over-engineer - keep scope appropriate for portfolio demonstration

## Question Templates by Script Category

### For Diagnostic/Monitoring Scripts

- What specific metrics/status information do you need?
- Should this run continuously or as one-time check?
- What thresholds should trigger warnings?
- How should alerts/notifications work?

### For Maintenance/Cleanup Scripts

- What should be cleaned/maintained?
- Should there be dry-run mode before actual cleanup?
- What safety backups are needed?
- How should logs of actions be maintained?

### For Automation Scripts

- What manual process are you trying to automate?
- How often will this run? (scheduled task vs. on-demand)
- What validation steps are needed before execution?
- How should failures be handled?

### For Reporting Scripts

- Who will read these reports?
- What time period should reports cover?
- Should reports include trends/comparisons?
- What format is most useful for your workflow?

## Adapting Questions Based on Request

**Tailor your questions to the specific script requested:**

- For "Network Diagnostics" → Focus on connectivity tests, remote systems, output detail
- For "User Management" → Focus on Active Directory vs. local, bulk operations, safety
- for "Service Monitor" → Focus on which services, restart policies, alerting
- For "File Cleanup" → Focus on criteria, safety mechanisms, logging

**Keep questions focused and relevant** - don't ask about remote computer support for a script that clearly only makes sense locally.

Remember: The quality of the PRD depends on understanding the real requirements. Good questions lead to great PRDs, which lead to excellent scripts.
