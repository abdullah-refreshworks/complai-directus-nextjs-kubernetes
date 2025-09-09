import { createDirectus, rest, staticToken, readItems } from '@directus/sdk';

// Define your schema
interface Schema {
  posts: {
    id: number;
    title: string;
    content: string;
    status: string;
    date_created: string;
    date_updated: string;
  }[];
  pages: {
    id: number;
    title: string;
    content: string;
    slug: string;
    status: string;
  }[];
}

// Create Directus client
const directusUrl = process.env.NEXT_PUBLIC_DIRECTUS_URL || 'http://localhost:8055';

export const directus = createDirectus<Schema>(directusUrl)
  .with(rest())
  .with(staticToken(process.env.DIRECTUS_TOKEN || ''));

// Helper functions
export async function getPosts() {
  try {
    const posts = await directus.request(
      readItems('posts', {
        filter: {
          status: {
            _eq: 'published'
          }
        },
        sort: ['-date_created']
      })
    );
    return posts;
  } catch (error) {
    console.error('Error fetching posts:', error);
    return [];
  }
}

export async function getPostBySlug(slug: string) {
  try {
    const posts = await directus.request(
      readItems('posts', {
        filter: {
          slug: {
            _eq: slug
          },
          status: {
            _eq: 'published'
          }
        },
        limit: 1
      })
    );
    return posts[0] || null;
  } catch (error) {
    console.error('Error fetching post:', error);
    return null;
  }
}

export async function getPages() {
  try {
    const pages = await directus.request(
      readItems('pages', {
        filter: {
          status: {
            _eq: 'published'
          }
        }
      })
    );
    return pages;
  } catch (error) {
    console.error('Error fetching pages:', error);
    return [];
  }
}

export async function getPageBySlug(slug: string) {
  try {
    const pages = await directus.request(
      readItems('pages', {
        filter: {
          slug: {
            _eq: slug
          },
          status: {
            _eq: 'published'
          }
        },
        limit: 1
      })
    );
    return pages[0] || null;
  } catch (error) {
    console.error('Error fetching page:', error);
    return null;
  }
}
