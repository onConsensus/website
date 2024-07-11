---
layout: page
title: Documentation
permalink: /documentation/
image:
---
Welcome to VJs Mag, your platform for sharing insights, articles, and visual content about the vibrant world of VJing and audiovisual art forms. To ensure your contributions reach our audience effectively, it is essential to understand the process of publishing documentation on our platform. This guide will walk you through the necessary steps and best practices for creating and publishing your work on VJs Mag.

### Table Of Contents

1. [Create an Account on GitHub](#1)
2. [Creating a private repository](#2)
3. [Creating Your Content](#3)
  - [Create a Markdown (.md) File](#3.1)
  - [Add a Header to Your Markdown File](#3.2)
  - [Article copyrights](#3.2)
4. [Adding Content](#4)
  - [Paragraphs](#4.1)
  - [Headings](#4.2)
  - [Ordered list](#4.3)
  - [Unordered list](#4.4)
  - [Table](#4.5)
  - [Quotes](#4.6)
  - [Syntax Highlighter](#4.7)
  - [Images](#4.8)
  - [Youtube Embed](#4.9)
  - [Vimeo Embed](#4.10)
  - [Links](#4.11)
5. [Uploading Media](#5)
  - [Media copyrights](#5.1)
6. [Writing Format](#6)
7. [Submitting Your Article](#7)
8. [Review and Approval Process](#8)
9. [Revenue Model Breakdown](#9)
10. [Revenue Distribution](#10)
11. [Hosting Media](#11)
12. [Youtube Revenue Distribution](#12)
13. [Payouts](#13)
14. [Scoring Algorithm](#14)
   - [Reputation Scoring System](#14.1)
   - [Overall Score Calculation](#14.2)

***

<a name="1"></a>

# How to Create an Account on GitHub

VJ journalists will need to create an account on GitHub. If you already have an account, you can skip this step.

## How to Create an Account on GitHub

1. **Go to GitHub's Sign-Up Page**:
   - Navigate to [GitHub Join Page](https://github.com/join).

2. **Fill Out the Registration Form**:
   - **Email Address**: Enter your email address.
   - **Password**: Create a strong password.
   - **Username**: Choose a unique username.
   - **Email Preferences**: Select your email preferences.

3. **Verify Your Account**:
   - Complete the CAPTCHA to verify that you are not a robot.

4. **Choose Your Plan**:
   - Select the plan that suits your needs (you can start with the free plan).

5. **Verify Your Email Address**:
   - GitHub will send a verification email to your provided email address. Open the email and click the verification link to activate your account.

## Additional Resources
- For detailed instructions, you can refer to the GitHub documentation on [creating an account](https://docs.github.com/en/get-started/start-your-journey/creating-an-account-on-github).

By following these steps, you will have a GitHub account ready to use for publishing and collaborating on VJs Mag.

***

<a name="2"></a>
# Creating a private repository

Creating a private repository on GitHub ensures that only you and your collaborators can access the repository. Here are the steps to create a private repository, which will be the same repository for all your articles and content:

1. **Open GitHub**:
   - Navigate to [GitHub](https://github.com) and sign in to your account.

2. **Go to Your Repositories**:
   - Click on your profile icon in the upper-right corner of the page.
   - From the dropdown menu, select "Your repositories."

3. **Create a New Repository**:
   - Click the "New" button to start creating a new repository.

4. **Fill in Repository Details**:
   - **Repository Name**: Type a memorable name for your repository.
   - **Description**: Optionally, add a description for your repository.
   - **Visibility**: Select the "Private" option to ensure the repository is not visible to the public.
   - **Initialize Repository**: Optionally, you can initialize the repository with a README, .gitignore, or a license file.

5. **Create Repository**:
   - Click the "Create repository" button to finalize the creation of your private repository.

### Additional Steps for Existing Repositories

If you want to change an existing public repository to private:

1. **Navigate to the Repository**:
   - Go to the main page of your repository on GitHub.

2. **Access Settings**:
   - Under your repository name, click on "Settings."

3. **Change Visibility**:
   - In the "Danger Zone" section at the bottom, click "Change repository visibility."
   - Select "Make private" and follow the prompts to confirm.

Following these steps will help you create a private repository on GitHub, ensuring your project remains confidential and secure.

***

<a name="3"></a>
# How to Create Content in Your GitHub Repository

Once you have created your first repository, you can start adding content by following these steps:

<a name="3.1"></a>

## Create a Markdown (.md) File

1. **Navigate to Your Repository**:
   - Go to your repository on GitHub.

2. **Create a New File**:
   - Click on the "Add file" button and select "Create new file".

3. **Name Your File**:
   - Name your file in the format `year-month-day-article-title.md`. For example: `2022-05-07-my-article-title.md`.

<a name="3.2"></a>

## Add a Header to Your Markdown File

At the beginning of your Markdown file, add the following header to define the layout, title, date, author, image, and tags for your article:

```markdown
---
layout: post
title: My article title
date: 2022-05-07 15:01:35 +0300
author: First Lastname
image: '/images/33.jpg'
tags: [category]
---
```

- **layout**: Indicates the layout template to be used.
- **title**: The title of your article.
- **date**: The publication date and time of the article.
- **author**: Your name.
- **image**: The path to an image that represents the article.
- **tags**: A list of categories or tags related to the article.

***

# Article copyrights

When submitting articles, please ensure to include any relevant copyright statements in the main repository. Including copyright and licensing information is crucial for compliance and collaboration purposes. It helps protect the rights of the authors and ensures that the work is properly attributed.

For further guidance on how to properly write copyright statements, refer to best practices in the industry. Including a copyright line in every file can also be beneficial.

## Links

1. [opensource.stackexchange.com - Should I include a copyright line in every file?](https://opensource.stackexchange.com/questions/292/should-i-include-a-copyright-line-in-every-file)
2. [github.com - Include copyright notice in every source file](https://github.com/LuaJIT/LuaJIT/issues/504)
3. [liferay.dev - How and why to properly write copyright statements in your code](https://liferay.dev/blogs/-/blogs/how-and-why-to-properly-write-copyright-statements-in-your-code)
4. [libguides.graduateinstitute.ch - Copyright and Academic Publishing](https://libguides.graduateinstitute.ch/copyright/academic-publishing)
5. [cwauthors.com - Who retains the copyright to a published article?](https://www.cwauthors.com/article/Who-retains-the-copyright-to-a-published-article)
6. [elsevier.com - Copyright | Elsevier policy](https://www.elsevier.com/about/policies-and-standards/copyright)

***

<a name="4"></a>
## Adding Content

Below the header, you can start adding your content. Use Markdown syntax to format your article. Here are some basic elements:

***

<a name="4.1"></a>
### Paragraphs

A paragraph looks like this — Globally incubate standards compliant channels before scalable benefits. Quickly disseminate superior deliverables whereas web-enabled applications. Quickly drive clicks-and-mortar catalysts for change before vertical architectures. Credibly reintermediate backend ideas for cross-platform models. Continually reintermediate integrated processes through technically sound intellectual capital. Holistically foster superior methodologies.

```
A paragraph looks like this — Globally incubate standards compliant channels before scalable benefits. Quickly disseminate superior deliverables whereas web-enabled applications. Quickly drive clicks-and-mortar catalysts for change before vertical architectures. Credibly reintermediate backend ideas for cross-platform models. Continually reintermediate integrated processes through technically sound intellectual capital. Holistically foster superior methodologies.
```

***
<a name="4.2"></a>

### Headings

# H1 Default styles for headings
## H2 Default styles for headings
### H3 Default styles for headings
#### H4 Default styles for headings
##### H5 Default styles for headings
###### H6 Default styles for headings

```
# H1 Default styles for headings
## H2 Default styles for headings
### H3 Default styles for headings
#### H4 Default styles for headings
##### H5 Default styles for headings
###### H6 Default styles for headings
```

***
<a name="4.3"></a>

### Ordered list example:

1. Morbi lectus risus iaculis vel suscipit turpis quis.
2. Curabitur sit amet mauris morbi in dui quis est pulvinar ullamcorper nulla facilisi.
3. Nullam mauris orci aliquet iaculis et neque viverra vitae ligula.
4. Proin quam etiam ultrices suspendisse in justo eu magna luctus lacinia suscipit.
5. Aenean lectus elit fermentum non convallis id sagittis at neque mauris orci.

```
1. Morbi lectus risus iaculis vel suscipit turpis quis.
2. Curabitur sit amet mauris morbi in dui quis est pulvinar ullamcorper nulla facilisi.
3. Nullam mauris orci aliquet iaculis et neque viverra vitae ligula.
4. Proin quam etiam ultrices suspendisse in justo eu magna luctus lacinia suscipit.
5. Aenean lectus elit fermentum non convallis id sagittis at neque mauris orci.
```

***
<a name="4.4"></a>

### Unordered list example:

* Etiam ultrices. Suspendisse in justo massa fusce non.
* Sed non quam. In vel mi sit amet augue congue elementum.
* Suspendisse in justo eu magna luctus suscipit sed lectus.
* Quisque volutpat condimentum velit class aptent taciti sociosqu torquent.
* Aenean lectus elit fermentum non convallis id sagittis at neque.

```
* Etiam ultrices. Suspendisse in justo massa fusce non.
* Sed non quam. In vel mi sit amet augue congue elementum.
* Suspendisse in justo eu magna luctus suscipit sed lectus.
* Quisque volutpat condimentum velit class aptent taciti sociosqu torquent.
* Aenean lectus elit fermentum non convallis id sagittis at neque.
```

***
<a name="4.5"></a>

## Table

<div class="table-container">
  <table>
    <tr><th>Header 1</th><th>Header 2</th><th>Header 3</th><th>Header 4</th><th>Header 5</th></tr>
    <tr><td>Row:1 Cell:1</td><td>Row:1 Cell:2</td><td>Row:1 Cell:3</td><td>Row:1 Cell:4</td><td>Row:1 Cell:5</td></tr>
    <tr><td>Row:2 Cell:1</td><td>Row:2 Cell:2</td><td>Row:2 Cell:3</td><td>Row:2 Cell:4</td><td>Row:2 Cell:5</td></tr>
    <tr><td>Row:3 Cell:1</td><td>Row:3 Cell:2</td><td>Row:3 Cell:3</td><td>Row:3 Cell:4</td><td>Row:3 Cell:5</td></tr>
    <tr><td>Row:4 Cell:1</td><td>Row:4 Cell:2</td><td>Row:4 Cell:3</td><td>Row:4 Cell:4</td><td>Row:4 Cell:5</td></tr>
    <tr><td>Row:5 Cell:1</td><td>Row:5 Cell:2</td><td>Row:5 Cell:3</td><td>Row:5 Cell:4</td><td>Row:5 Cell:5</td></tr>
    <tr><td>Row:6 Cell:1</td><td>Row:6 Cell:2</td><td>Row:6 Cell:3</td><td>Row:6 Cell:4</td><td>Row:6 Cell:5</td></tr>
  </table>
</div>

```
<div class="table-container">
  <table>
    <tr><th>Header 1</th><th>Header 2</th><th>Header 3</th><th>Header 4</th><th>Header 5</th></tr>
    <tr><td>Row:1 Cell:1</td><td>Row:1 Cell:2</td><td>Row:1 Cell:3</td><td>Row:1 Cell:4</td><td>Row:1 Cell:5</td></tr>
    <tr><td>Row:2 Cell:1</td><td>Row:2 Cell:2</td><td>Row:2 Cell:3</td><td>Row:2 Cell:4</td><td>Row:2 Cell:5</td></tr>
    <tr><td>Row:3 Cell:1</td><td>Row:3 Cell:2</td><td>Row:3 Cell:3</td><td>Row:3 Cell:4</td><td>Row:3 Cell:5</td></tr>
    <tr><td>Row:4 Cell:1</td><td>Row:4 Cell:2</td><td>Row:4 Cell:3</td><td>Row:4 Cell:4</td><td>Row:4 Cell:5</td></tr>
    <tr><td>Row:5 Cell:1</td><td>Row:5 Cell:2</td><td>Row:5 Cell:3</td><td>Row:5 Cell:4</td><td>Row:5 Cell:5</td></tr>
    <tr><td>Row:6 Cell:1</td><td>Row:6 Cell:2</td><td>Row:6 Cell:3</td><td>Row:6 Cell:4</td><td>Row:6 Cell:5</td></tr>
  </table>
</div>
```

***
<a name="4.6"></a>

## Quotes

#### A quote looks like this:

> The longer I live, the more I realize that I am never wrong about anything, and that all the pains I have so humbly taken to verify my notions have only wasted my time!
>
> <cite>– George Bernard Shaw</cite>

```
> The longer I live, the more I realize that I am never wrong about anything, and that all the pains I have so humbly taken to verify my notions have only wasted my time!
>
> <cite>– George Bernard Shaw</cite>
```

***
<a name="4.7"></a>

## Syntax Highlighter

```css
body {
  margin: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  width: 100vw;
  background-color: #1c2021;
}

li {
  width: 200px;
  min-height: 250px;
  border: 1px solid #000;
  display: inline-block;
  vertical-align: top;
  margin: 5px;
}
```

```js
  $('.top').click(function () {
    $('html, body').stop().animate({ scrollTop: 0 }, 'slow', 'swing');
  });
  $(window).scroll(function () {
    if ($(this).scrollTop() > $(window).height()) {
      $('.top').addClass("top-active");
    } else {
      $('.top').removeClass("top-active");
    };
  });
```

```
```
content
```
```

***
<a name="4.8"></a>

## Images

![Shopping]({{site.baseurl}}/images/mapping-festival-2011-2.jpg#wide)
*Photo by [Guillaume Lauzier](https://www.guillaumelauzier.com/) on [Mapping Festival](https://www.mappingfestival.com)*

```
![Shopping]({{site.baseurl}}/images/mapping-festival-2011-2.jpg#wide)
*Photo by [Guillaume Lauzier](https://www.guillaumelauzier.com/) on [Mapping Festival](https://www.mappingfestival.com)*
```

<div class="gallery-box">
  <div class="gallery">
    <img src="/images/mapping-festival-2011-3.jpg" loading="lazy">
    <img src="/images/mapping-festival-2011-4.jpg" loading="lazy">
    <img src="/images/mapping-festival-2011-5.jpg" loading="lazy">
    <img src="/images/mapping-festival-2011-6.jpg" loading="lazy">
    <img src="/images/mapping-festival-2011-7.jpg" loading="lazy">
    <img src="/images/mapping-festival-2011-2.jpg" loading="lazy">
  </div>
  <em>Gallery / <a href="https://www.guillaumelauzier.com" target="_blank">Guillaume Lauzier</a></em>
</div>

```
<div class="gallery-box">
  <div class="gallery">
    <img src="/images/mapping-festival-2011-3.jpg" loading="lazy">
    <img src="/images/mapping-festival-2011-4.jpg" loading="lazy">
    <img src="/images/mapping-festival-2011-5.jpg" loading="lazy">
    <img src="/images/mapping-festival-2011-6.jpg" loading="lazy">
    <img src="/images/mapping-festival-2011-7.jpg" loading="lazy">
    <img src="/images/mapping-festival-2011-2.jpg" loading="lazy">
  </div>
  <em>Gallery / <a href="https://www.guillaumelauzier.com" target="_blank">Guillaume Lauzier</a></em>
</div>
```

![Mapping Festival]({{site.baseurl}}/images/mapping-festival-2011-2.jpg)
*Photo by [Guillaume Lauzier](https://www.guillaumelauzier.com) on [Mapping Festival](https://www.mappingfestival.com)*

```
![Mapping Festival]({{site.baseurl}}/images/mapping-festival-2011-2.jpg)
*Photo by [Guillaume Lauzier](https://www.guillaumelauzier.com) on [Mapping Festival](https://www.mappingfestival.com)*
```

***
<a name="4.9"></a>

## Youtube Embed

<p><iframe src="https://www.youtube.com/embed/I_LrJjraWKQ?si=PvR8qV-3c3UfmYjY" loading="lazy" frameborder="0" allowfullscreen></iframe></p>

```
<p><iframe src="https://www.youtube.com/embed/I_LrJjraWKQ?si=PvR8qV-3c3UfmYjY" loading="lazy" frameborder="0" allowfullscreen></iframe></p>
```

***
<a name="4.10"></a>

## Vimeo Embed

<p><iframe src="https://player.vimeo.com/video/55630271?h=d36b8b4cbb" loading="lazy" width="640" height="360" frameborder="0" allowfullscreen></iframe></p>

```
<p><iframe src="https://player.vimeo.com/video/55630271?h=d36b8b4cbb" loading="lazy" width="640" height="360" frameborder="0" allowfullscreen></iframe></p>
```

***
<a name="4.11"></a>

### Links
```markdown
[Link text](http://example.com)
```

***
<a name="5"></a>

# How to Upload Media on GitHub and Create an "Images" Folder

To include media such as images in your GitHub repository, follow these steps to create a folder named "Images" in the same repository as your Markdown file:

## Step-by-Step Instructions

### 1. Navigate to Your Repository
- Go to [GitHub](https://github.com/) and log in to your account.
- Navigate to the repository where your Markdown file is located.

### 2. Create the "Images" Folder
- In the repository, click on the "Add file" button.
- Select "Create new file" from the dropdown menu.
- In the text field for the new file name, type `Images/image.jpg`. This will create a new folder named "Images" and a placeholder file within it.
- Click "Commit new file" to create the folder. The placeholder file can be deleted later once you've uploaded your images.

### 3. Upload Images to the "Images" Folder
- Click on the "Images" folder to open it.
- Click on the "Add file" button again and select "Upload files".
- Drag and drop your image files into the upload area or click "choose your files" to select them from your computer.
- After selecting the files, click "Commit changes" to upload the images to the "Images" folder.

### 4. Reference Images in Your Markdown File
- See [Header to Your Markdown File](#3.1)

### Example
If you uploaded an image named `/images/example.jpg`, your Markdown file should include:
```markdown
---
layout: post
title: My article title
date: 2022-05-07 15:01:35 +0300
author: First Lastname
image: '/images/33.jpg'
tags: [category]
---
```

### Additional Tips
- Ensure your image files have descriptive names for better organization and clarity.
- Regularly commit and push your changes to keep your repository updated.

***
<a name="5.1"></a>

# Uploading Media

When submitting media content such as photography, graphic designs, and videos, please ensure to include any relevant copyright statements in the /images folder of the main repository. Properly attributing the creators of these works is essential for compliance and collaboration purposes. It helps protect the rights of the authors and ensures that the work is properly attributed.

Here are some key points to remember:

1. **Creative Commons Images**:
   - Even images licensed under Creative Commons are protected by copyright and require appropriate attribution.

2. **Permission and Attribution**:
   - Using copyrighted images without permission is considered copyright infringement, even if you provide attribution.

3. **Fair Use**:
   - Understand the principles of fair use when using images online to avoid legal issues.

4. **Quoting Images**:
   - In some jurisdictions, quoting images for critique or discussion may be permitted under copyright law.

5. **Avoiding Infringement**:
   - Always look for image credits, links, or contact information when using images from other websites to ensure proper usage.

By including copyright files in the `/images` folder, you help maintain the integrity and legality of the content within the repository.

## Links

1. [pixsy.com - A Beginner's Guide To Using Copyrighted Images](https://www.pixsy.com/copyright/using-copyrighted-images)
2. [quora.com - Is it legal to use copyrighted images if you give attribution](https://www.quora.com/Is-it-legal-to-use-copyrighted-images-if-you-give-attribution-and-link-back-to-the-source-site)
3. [socialmediaexaminer.com - Copyright Fair Use and How it Works for Online Images](https://www.socialmediaexaminer.com/copyright-fair-use-and-how-it-works-for-online-images/)
4. [subjectguides.york.ac.uk - Using images - Copyright: a Practical Guide](https://subjectguides.york.ac.uk/copyright/images)
5. [resourcespace.com - How to avoid copyright infringement with images](https://www.resourcespace.com/blog/how-to-avoid-copyright-infringement-with-images)
6. [gov.uk - Copyright notice: digital images, photographs and the internet](https://www.gov.uk/government/publications/copyright-notice-digital-images-photographs-and-the-internet/copyright-notice-digital-images-photographs-and-the-internet)

***

<a name="6"></a>

# Writing Format

A good writing format for an audiovisual art magazine should include clear sections, proper citation of audiovisual materials, and a consistent style to ensure readability and professionalism. Here’s a suggested format:

### 1. Title and Author Information

Go to [Title and Author Information](#3.1)

### 2. Introduction
- Brief introduction to the topic, setting the context for the readers.
- Purpose and scope of the article.

### 3. Main Content
- **Subheadings**: Use subheadings to organize content into clear sections.
- **Text**: Write clear, concise, and engaging text. Each section should cover different aspects of the topic.
- **Visuals**: Include photographs or videos relevant to the content. Each visual should be accompanied by a caption and proper credit to the creator.

### 4. Audiovisual Content
- **Photographs**: 
  - Include high-resolution images.
  - Caption format: See [Images](#4.8)
  - Example: _Sunset Over the Mountains [Photograph]. John Doe. 2024._
- **Videos**:
  - Embed or link videos.
  - Caption format: "Title of the Video [Video]. Author. Year."
  - Example: _Exploring Urban Art [Video]. Jane Smith. 2024._

### 5. Citations and References
- Use APA style for citing audiovisual materials.
  - **Photographs**:
    - Format: "Author, A. A. (Year). Title of the photograph [Photograph]. URL"
  - **Videos**:
    - Format: "Author, A. A. (Year, Month Date). Title of the video [Video]. URL"
  - Example for a photograph: _Doe, J. (2024). Sunset over the mountains [Photograph]. Retrieved from https://example.com_
  - Example for a video: _Smith, J. (2024, June 18). Exploring urban art [Video]. Retrieved from https://example.com_

### 6. Conclusion
- Summarize the key points discussed in the article.
- Provide a closing statement or call to action.

### 7. Author Bio and Contact Information
- Include a brief bio of the author and contact information for readers to reach out.

### 8. Additional Resources
- List any additional resources or related articles for further reading.

This format ensures that the content is well-organized, visually appealing, and provides proper credit to all audiovisual contributors.

***

<a name="7"></a>

# Submitting Your Article

To submit your article, follow these steps:

1. **Add a Collaborator**:
   - Go to your repository on GitHub.
   - Click on "Settings" in your repository.
   - Navigate to "Manage Access" and click on "Invite a collaborator".
   - Add `@guillaumelauzier` as a collaborator [[3](https://docs.github.com/articles/inviting-collaborators-to-a-personal-repository)].

2. **Add a Webhook**:
   - In your repository settings, navigate to "Webhooks".
   - Click "Add webhook".
   - Paste the following URL into the "Payload URL" field: 
   ```
   https://discord.com/api/webhooks/1253330995495702598/_CGbjU1C9OWbY70Bll8CKcJYTsR_8XAHJ-ktKd0SogfmQ-gi5c-ujo-XVks4uv-oDgm_
   ```
   - Choose content type `application/json` and configure any additional settings as needed [[2](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-security-and-analysis-settings-for-your-repository)].
   - Select "Content type": application/x-www-form-urlencoded
   - Keep "Secret" empty
   - Under "Which events would you like to trigger this webhook?" select "Send me everything."
   - Make sure "Active (We will deliver event details when this hook is triggered.)" is checked

***

<a name="8"></a>

# Review and Approval Process

Once your repository has been shared with @guillaumelauzier and the following webhook has been added: [Webhook URL](https://discord.com/api/webhooks/1253330995495702598/_CGbjU1C9OWbY70Bll8CKcJYTsR_8XAHJ-ktKd0SogfmQ-gi5c-ujo-XVks4uv-oDgm_), our AI system performs an initial review. This includes checking for copyright infringements, typos, plagiarism, AI usage, and duplicates. The AI outputs a report and corrects any issues that can be addressed automatically. After this, the article goes through the following editorial process:

1. **Initial Quality Check**:
   - The editorial office performs an initial check to ensure the article meets basic quality standards and fits the journal's scope.

2. **Peer Review**:
   - The article is sent out for peer review by experts in the field.
   - Reviewers evaluate the article's quality, originality, and relevance.

3. **Revisions**:
   - Based on reviewers' feedback, authors may need to make revisions to their article.
   - The revised article may undergo additional rounds of review.

4. **Editorial Decision**:
   - The editor makes a final decision to accept, reject, or request further revisions for the article.

5. **Copyediting and Proofreading**:
   - Accepted articles undergo rigorous copyediting and proofreading to correct spelling, grammar, and formatting issues.
   - This process ensures clarity, readability, and adherence to publication standards.

6. **Copyright and Permissions**:
   - Authors may need to sign copyright transfer agreements or provide permissions for previously published material.
   - Ensuring proper copyright management is crucial for legal compliance.

You will receive an approval through GitHub directly in your repository before we merge your repository to the main editorial branch.

***

<a name="9"></a>

## Revenue Model Breakdown

The revenue model for journalists on the online magazine will be based on several key metrics:

1. **Number of Returning Visitors**:
   - A good returning visitor rate is anything over 30%. This means that if you have 10,000 visitors, at least 3,000 should be returning visitors to indicate a healthy engagement rate.

2. **Number of New Visitors**:
   - New visitors typically represent a significant portion of your traffic. For example, if you have 10,000 visitors in a week, approximately 70% (or 7,000) might be new visitors, indicating effective outreach and marketing efforts.

3. **Geographic Location**:
   - The value of visitors varies by region. For instance, visitors from North America and Western Europe can be 1.5 to 2 times more valuable in terms of ad revenue and purchase power compared to visitors from other regions.

4. **Time Spent on the Article**:
   - A good average time spent on an article is around 2-3 minutes. If visitors are spending 5 minutes or more, it indicates highly engaging content. For instance, an article with an average read time of 5 minutes can be considered highly valuable.

5. **Quality of Referring Links**:
   - High-quality referring links typically come from websites with high domain authority (DA). A good benchmark is a DA score of 50 or higher. For example, a link from a site with a DA of 70 is significantly more valuable than one with a DA of 20.

6. **Outgoing Clicks**:
   - A good rate of outgoing clicks is around 5-10% of total visits. For example, if an article has 1,000 views, having 50 to 100 outgoing clicks indicates strong engagement with external links.

The magazine will take 50% of the total revenue generated. The remaining 50% will be distributed among the contributors: writers, photographers, and videographers.

***
<a name="10"></a>

## Article Percentage Distribution for Contributors

### Writer and Photographer Distribution
- **Magazine**: 50%
- **Writer**: 30%
- **Photographer**: 20%

### Writer and Videographer Distribution
- **Magazine**: 50%
- **Writer**: 30%
- **Videographer**: 20%

### Writer, Photographer, and Videographer Distribution
If an article involves a writer, photographer, and videographer, the distribution will be:
- **Magazine**: 50%
- **Writer**: 20%
- **Photographer**: 15%
- **Videographer**: 15%

***
<a name="11"></a>

## Hosting and Revenue Distribution for Media

### Photos
- All photos must be hosted on GitHub.
- The revenue generated from articles including photographs will follow the distribution mentioned above.

### Videos
- All videos must be hosted on the VJs TV YouTube channel.
- The revenue distribution for videographers will be calculated based on video performance metrics on YouTube, such as views, watch time, and engagement.

### Credentials
- All contributors (writers, photographers, videographers) will be credited appropriately in the article and any associated media.

***
<a name="12"></a>

# YouTube Revenue Distribution for Contributors

In addition to the article revenue distribution, the YouTube revenue generated from videos hosted on the VJs TV YouTube channel will be distributed among the magazine, videographer, and video journalist. Here is the detailed distribution model:

## Distribution Model

### Base Model
- **Magazine**: 30%
- **Remaining Revenue**: 70% (to be split among contributors)

### Scenario 1: Magazine, Videographer, and Video Journalist
- **Magazine**: 30%
- **Videographer**: 40%
- **Video Journalist**: 30%

### Scenario 2: Magazine and Videographer Only
- **Magazine**: 30%
- **Videographer**: 70%

### Scenario 3: Magazine and Video Journalist Only
- **Magazine**: 30%
- **Video Journalist**: 70%

## Example Calculation

For instance, if a video generates $1,000 in YouTube ad revenue:

- **Scenario 1**:
  - **Magazine**: $300
  - **Videographer**: $400
  - **Video Journalist**: $300

- **Scenario 2**:
  - **Magazine**: $300
  - **Videographer**: $700

- **Scenario 3**:
  - **Magazine**: $300
  - **Video Journalist**: $700

By maintaining the magazine's share at 30% across various scenarios, this model ensures the magazine's operational costs are covered while fairly compensating the content creators based on their roles.

***
<a name="13"></a>

# Payouts

Payouts will be made on a monthly basis, based on the total magazine revenue. Your total score, derived from various engagement metrics, will determine your share of the total revenue. Below is an example breakdown:

## Example Breakdown
- Total Monthly Revenue: $25,000
- 100 Authors (Articles)
- 20 Videographers (YouTube Videos)
- 50% of revenue allocated to articles: $12,500
- 30% of revenue allocated to YouTube videos: $7,500

### Revenue Breakdown Model

#### For Articles:
1. **Number of Returning Visitors**:
   - A good returning visitor rate is anything over 30%. For example, with 10,000 visitors, at least 3,000 should be returning visitors to indicate a healthy engagement rate.

2. **Number of New Visitors**:
   - New visitors typically represent a significant portion of your traffic. For example, if you have 10,000 visitors in a week, approximately 70% (or 7,000) might be new visitors, indicating effective outreach and marketing efforts.

3. **Geographic Location**:
   - The value of visitors varies by region. For instance, visitors from North America and Western Europe can be 1.5 to 2 times more valuable in terms of ad revenue and purchase power compared to visitors from other regions.

4. **Time Spent on the Article**:
   - A good average time spent on an article is around 2-3 minutes. If visitors are spending 5 minutes or more, it indicates highly engaging content. For instance, an article with an average read time of 5 minutes can be considered highly valuable.

5. **Quality of Referring Links**:
   - High-quality referring links typically come from websites with high domain authority (DA). A good benchmark is a DA score of 50 or higher. For example, a link from a site with a DA of 70 is significantly more valuable than one with a DA of 20.

6. **Outgoing Clicks**:
   - A good rate of outgoing clicks is around 5-10% of total visits. For example, if an article has 1,000 views, having 50 to 100 outgoing clicks indicates strong engagement with external links.

#### For YouTube Videos:
- Revenue is split among videographers based on similar engagement metrics adapted for video content.
- Example: From the $7,500 allocated to YouTube revenue, if a video contributes 10% of the total engagement, it would earn $750.

### Distribution:
- **Authors (Articles)**: Share of $12,500 based on engagement metrics.
- **Videographers (YouTube)**: Share of $7,500 based on YouTube metrics.

Payouts will be made via Revolut.

<a name="14"></a>

# Scoring Algorithm for Rating Writers and Contributors

This algorithm will rate writers and contributors based on several key metrics that contribute to the overall value and engagement of their articles. The metrics and their weights are:

1. **Returning Visitors** (20%)
2. **New Visitors** (15%)
3. **Geographic Location** (15%)
4. **Time Spent on the Article** (15%)
5. **Quality of Referring Links** (15%)
6. **Outgoing Clicks** (10%)
7. **Number of Articles Published** (5%)
8. **Value of the Section** (5%)

### Metric Formulas and Normalization

Each metric is normalized to a scale of 0 to 100.

1. **Returning Visitors (RV)**:
<p>
                <code>Score<sub>RV</sub> = min(100, (Returning Visitors / Total Visitors) * 333.33)</code>
</p>
   - 30% returning visitors correspond to a full score (100).

2. **New Visitors (NV)**:
<p>
                <code>Score<sub>NV</sub> = min(100, (New Visitors / Total Visitors) * 142.86)</code>
</p>
   - 70% new visitors correspond to a full score (100).

3. **Geographic Location (GL)**:
<p>
                <code>Score<sub>GL</sub> = min(100, (High-value Region Visitors / Total Visitors) * 200)</code>
</p>
   - 50% high-value region visitors correspond to a full score (100).

4. **Time Spent on the Article (TS)**:
<p>
                <code>Score<sub>TS</sub> = min(100, (Average Time Spent / 5) * 100)</code>
</p>
   - 5 minutes average time spent correspond to a full score (100).

5. **Quality of Referring Links (QR)**:
<p>
                <code>Score<sub>QR</sub> = min(100, (Average DA of Referring Links / 50) * 100)</code>
</p>
   - DA of 50 correspond to a full score (100).

6. **Outgoing Clicks (OC)**:
<p>
                <code>Score<sub>OC</sub> = min(100, (Outgoing Clicks / Total Views) * 1000)</code>
</p>
   - 10% outgoing clicks correspond to a full score (100).

7. **Number of Articles Published (NA)**:
<p>
                <code>Score<sub>NA</sub> = min(100, (Articles Published / Target Number of Articles) * 100)</code>
</p>
   - Normalized so that the target number of articles corresponds to a full score (100).

8. **Value of the Section (VS)**:
<p>
                <code>Score<sub>VS</sub> = min(100, (Section Weight / Total Sections Weight) * 100)</code>
</p>
   - Based on the relative weight of the section. Sections with fewer articles have higher weight.

<a name="14.1"></a>

# Reputation Scoring System:
The reputation of the writer will be based on historical performance metrics and qualitative assessments:
- **Article Performance** (average score of previous articles)
- **Peer Reviews** (average score from peer reviews)
- **Editorial Feedback** (average score from editorial reviews)
<p>
        <code>Reputation Score = 0.5 * Article Performance + 0.3 * Peer Reviews + 0.2 * Editorial Feedback</code>
</p>
<a name="14.2"></a>

# Overall Score Calculation:
<p>
        <code>Total Score = 0.20 * Score<sub>RV</sub> + 0.15 * Score<sub>NV</sub> + 0.15 * Score<sub>GL</sub> + 0.15 * Score<sub>TS</sub> + 0.15 * Score<sub>QR</sub> + 0.10 * Score<sub>OC</sub> + 0.05 * Score<sub>NA</sub> + 0.05 * Score<sub>VS</sub></code>
</p>
### Example Calculation:
Assume the following metrics for a writer’s article:

- Total Visitors: 10,000
- Returning Visitors: 3,500 (35%)
- New Visitors: 6,500 (65%)
- High-value Region Visitors: 4,000 (40%)
- Average Time Spent: 4 minutes
- Average DA of Ref