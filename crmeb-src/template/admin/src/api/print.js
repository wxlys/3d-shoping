import request from '@/libs/request';

export function printQueueList(data) {
  return request({
    url: '/print/queue/list',
    method: 'get',
    params: data,
  });
}

export function printQueueStart(data) {
  return request({
    url: '/print/queue/start',
    method: 'post',
    data,
  });
}

export function printQueueComplete(data) {
  return request({
    url: '/print/queue/complete',
    method: 'post',
    data,
  });
}

export function printQueueAdjust(data) {
  return request({
    url: '/print/queue/adjust',
    method: 'post',
    data,
  });
}

export function printQueueProgress(data) {
  return request({
    url: '/print/queue/progress',
    method: 'post',
    data,
  });
}

export function printInquiryList(data) {
  return request({
    url: '/print/inquiry/list',
    method: 'get',
    params: data,
  });
}

export function printInquiryInfo(id) {
  return request({
    url: `/print/inquiry/info/${id}`,
    method: 'get',
  });
}

export function printInquiryQuote(id, data) {
  return request({
    url: `/print/inquiry/quote/${id}`,
    method: 'post',
    data,
  });
}

export function printInquiryExpire(id) {
  return request({
    url: `/print/inquiry/expire/${id}`,
    method: 'post',
  });
}
